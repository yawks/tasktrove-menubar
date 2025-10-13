import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var viewModel: TaskListViewModel
    let isFiltersExpanded: Bool // État des filtres pour ajuster la hauteur du footer
    
    // Track reported row heights
    @State private var reportedRowHeights: [CGFloat] = []
    // Track available list height
    @State private var availableHeight: CGFloat = 600
    // Track the first observed available height to avoid later layout expansions hiding the header
    @State private var firstAvailableHeight: CGFloat? = nil
    // Computed exact height for the list so we don't leave a gap after the last row
    @State private var computedListHeight: CGFloat = 300
    // No per-row stretching: we'll use measured median row height for sizing
    // Per-row height to apply so content fills the computedListHeight exactly
    @State private var perRowHeight: CGFloat? = nil
    // Debug state (visible only in DEBUG builds)
    @State private var lastMedian: CGFloat = 0
    @State private var lastComputedItems: Int = 0
    @State private var lastRawFit: CGFloat = 0
    @State private var lastFrac: CGFloat = 0
    @State private var lastUsableHeight: CGFloat = 0
    @State private var lastReservedFooter: CGFloat = 0
    // Measured header height (falls back to this estimate if not available)
    @State private var measuredHeaderHeight: CGFloat? = nil
    private let headerEstimate: CGFloat = 70
    // Footer height estimates (collapsed vs expanded)
    private let footerCollapsedEstimate: CGFloat = 40  // Bouton "Filters" simple
    private let footerExpandedEstimate: CGFloat = 80   // Tous les filtres visibles

    var body: some View {
        VStack(spacing: 0) {
            // Use a ScrollView + LazyVStack for precise control over row heights and spacing
            let tasks = viewModel.paginatedTasks
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(tasks.enumerated()), id: \.element.id) { pair in
                        let idx = pair.offset
                        let task = pair.element
                        TaskRowView(task: task)
                            .frame(height: perRowHeight)
                        if idx < tasks.count - 1 {
                            Divider().frame(height: 1)
                        }
                    }
                }
            }
        }
    // Apply a min/max height so the list grows up to usableHeight but doesn't force a fixed height
    .frame(minHeight: computedListHeight, maxHeight: min(firstAvailableHeight ?? availableHeight, 900))
        // Measure available height for the container and compute itemsPerPage
        .background(
            GeometryReader { geo in
                Color.clear.onAppear {
                    availableHeight = geo.size.height
                    if firstAvailableHeight == nil {
                        firstAvailableHeight = geo.size.height
                    }
                    updateItemsPerPage()
                }
                .onChange(of: geo.size.height) { _, newH in
                    availableHeight = newH
                    // Do not update firstAvailableHeight after initial measurement to avoid layout jumps
                    updateItemsPerPage()
                }
            }
        )
        // Listen for header height measurement from the parent view
        .onPreferenceChange(HeaderHeightPreferenceKey.self) { value in
            if let v = value, v > 0 {
                measuredHeaderHeight = v
                updateItemsPerPage()
            }
        }

        .onPreferenceChange(RowHeightPreferenceKey.self) { value in
            // Keep a small rolling sample of reported row heights
            reportedRowHeights.append(value)
            if reportedRowHeights.count > 20 { reportedRowHeights.removeFirst() }
            updateItemsPerPage()
        }
        // Recalculate when the number of tasks changes
        .onChange(of: viewModel.paginatedTasks.count) { _, _ in
            updateItemsPerPage()
        }
        // Recalculate when filter expansion state changes
        .onChange(of: isFiltersExpanded) { _, _ in
            updateItemsPerPage()
        }
        #if DEBUG
        .overlay(
                VStack(alignment: .trailing, spacing: 2) {
                Text("avail: \(String(format: "%.0f", availableHeight))")
                Text("firstAvail: \(String(format: "%.0f", firstAvailableHeight ?? availableHeight))")
                Text("median: \(String(format: "%.1f", lastMedian))")
                Text("rawFit: \(String(format: "%.2f", lastRawFit)) frac: \(String(format: "%.2f", lastFrac))")
                Text("headerEst: \(String(format: "%.0f", headerEstimate))")
                Text("footerH: \(String(format: "%.0f", lastReservedFooter))")
                Text("usable: \(String(format: "%.0f", lastUsableHeight))")
                Text("items: \(lastComputedItems)")
                Text("height: \(String(format: "%.0f", computedListHeight))")
            }
            .font(.caption2)
            .padding(4)
            .background(Color.black.opacity(0.7))
            .foregroundColor(.white)
            .cornerRadius(4)
            .padding(6)
            , alignment: .topTrailing
        )
        #endif
    }

    private func updateItemsPerPage() {
        // Use the median reported row height (fallback to a sensible default)
        let defaultRowHeight: CGFloat = 64.0
        let rowHeights = reportedRowHeights.isEmpty ? [defaultRowHeight] : reportedRowHeights
        let sorted = rowHeights.sorted()
                    let median = sorted[sorted.count / 2]

        // For calculating how many items fit, use a smaller row height estimate
        // This avoids circular dependency where measured height depends on current item count
        let calculationRowHeight: CGFloat = 48.0 // Optimistic estimate for space calculation
        
        // For display, use measured median if available, otherwise fallback
        let displayRowHeight = (median.isFinite && median > 0) ? median : defaultRowHeight
        lastMedian = displayRowHeight

        // Guard availableHeight; if it's invalid use a basic fallback derived from a fixed default
        guard availableHeight.isFinite && availableHeight > 0 else {
            // If we don't know available height, pick a reasonable default page size
            let fallbackItems = max(1, Int(floor(500.0 / calculationRowHeight))) // ~7
            if viewModel.itemsPerPage != fallbackItems {
                viewModel.itemsPerPage = fallbackItems
                viewModel.resetPagination()
            }
            // also set a sensible visual height
            computedListHeight = CGFloat(viewModel.itemsPerPage) * calculationRowHeight
            return
        }

    // Use the first observed available height to avoid a second-pass expansion hiding header
    let usableHeight = firstAvailableHeight ?? availableHeight
    // Reserve the measured header and footer height if available, otherwise fall back to estimates
    let reservedHeader = (measuredHeaderHeight != nil && measuredHeaderHeight! > 0) ? measuredHeaderHeight! : headerEstimate
    let reservedFooter = isFiltersExpanded ? footerExpandedEstimate : footerCollapsedEstimate
    let usableHeightClamped = max(0, usableHeight - reservedHeader - reservedFooter)
    lastUsableHeight = usableHeightClamped
    lastReservedFooter = reservedFooter
    // Compute how many rows fit based on the consistent calculation height
    let rawFit = usableHeightClamped / calculationRowHeight
    // Use a more aggressive approach: fit as many items as possible in available space
    // Round to nearest integer to maximize space usage
    let computedItems = max(1, Int(round(rawFit)))
    // We'll account for divider heights (1pt each) between rows when distributing height
    let dividerThickness: CGFloat = 1.0
    lastComputedItems = computedItems
    lastRawFit = rawFit
    lastFrac = rawFit - floor(rawFit)

            if viewModel.itemsPerPage != computedItems {
                viewModel.itemsPerPage = computedItems
                viewModel.resetPagination()
            }

                // Always use natural row height and let ScrollView handle overflow
                let totalDividerHeight = CGFloat(max(0, computedItems - 1)) * dividerThickness
                let naturalHeight = CGFloat(computedItems) * displayRowHeight + totalDividerHeight
                
                // Use natural height, limited by max container height for scroll
                computedListHeight = min(naturalHeight, min(usableHeightClamped, 900))
                perRowHeight = displayRowHeight
    }
}

// PreferenceKey for row heights
struct RowHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// Preference key for the header height measured in ContentView
struct HeaderHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = nextValue() ?? value
    }
}

// A preview provider to help develop the UI in isolation.
#if DEBUG
struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        TaskListView(isFiltersExpanded: false)
            .frame(width: 400, height: 500)
    }
}
#endif