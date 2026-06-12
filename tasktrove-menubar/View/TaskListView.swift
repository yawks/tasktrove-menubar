import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var viewModel: TaskListViewModel
    let isFiltersExpanded: Bool // État des filtres pour ajuster la hauteur du footer

    // Track reported row heights
    @State private var reportedRowHeights: [CGFloat] = []
    // Track available list height (height allocated to TaskListView by SwiftUI, header/footer already excluded)
    @State private var availableHeight: CGFloat = 600
    // Guard: skip updateItemsPerPage until onAppear has provided a real geometry measurement
    @State private var hasAppeared = false
    // Computed exact height for the list so we don't leave a gap after the last row
    @State private var computedListHeight: CGFloat = 300
    // Per-row height; may be stretched to fill remaining space
    @State private var perRowHeight: CGFloat? = nil
    // Debug state (visible only in DEBUG builds)
    @State private var lastMedian: CGFloat = 0
    @State private var lastComputedItems: Int = 0
    @State private var lastRawFit: CGFloat = 0
    @State private var lastFrac: CGFloat = 0
    @State private var lastUsableHeight: CGFloat = 0

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
    .frame(minHeight: computedListHeight, maxHeight: min(viewModel.firstAvailableHeight ?? availableHeight, 900))
        // Measure available height for the container and compute itemsPerPage
        .background(
            GeometryReader { geo in
                Color.clear.onAppear {
                    availableHeight = geo.size.height
                    hasAppeared = true
                    if viewModel.firstAvailableHeight == nil && !isFiltersExpanded {
                        viewModel.firstAvailableHeight = geo.size.height
                    }
                    updateItemsPerPage()
                }
                .onChange(of: geo.size.height) { _, newH in
                    availableHeight = newH
                    if viewModel.firstAvailableHeight == nil && !isFiltersExpanded {
                        viewModel.firstAvailableHeight = newH
                    }
                    updateItemsPerPage()
                }
            }
        )
        .onPreferenceChange(RowHeightPreferenceKey.self) { value in
            // Keep a small rolling sample of reported row heights
            reportedRowHeights.append(value)
            if reportedRowHeights.count > 20 { reportedRowHeights.removeFirst() }
            // Skip until onAppear has provided a real geometry measurement (avoids using
            // the default availableHeight=600 before the window is measured).
            guard hasAppeared else { return }
            updateItemsPerPage()
        }
        // Recalculate when the number of tasks changes
        .onChange(of: viewModel.paginatedTasks.count) { old, new in
            print("🟡 [TaskListView] paginatedTasks.count \(old)→\(new) filtered=\(viewModel.filteredTasksCache.count) items=\(viewModel.itemsPerPage) pages=\(viewModel.totalPages)")
            updateItemsPerPage()
        }
        // Recalculate when totalPages changes so pagerReservation is applied immediately
        // (paginatedTasks.count stays the same when going from 1→2 pages, so this is needed)
        .onChange(of: viewModel.totalPages) { old, new in
            print("🟡 [TaskListView] totalPages \(old)→\(new) filtered=\(viewModel.filteredTasksCache.count) items=\(viewModel.itemsPerPage) firstAvail=\(viewModel.firstAvailableHeight.map{Int($0)} ?? -1) avail=\(Int(availableHeight))")
            updateItemsPerPage()
        }
        // Recalculate when filter expansion state changes
        .onChange(of: isFiltersExpanded) { _, newExpanded in
            print("🟡 [TaskListView] isFiltersExpanded→\(newExpanded) firstAvail=\(viewModel.firstAvailableHeight.map{Int($0)} ?? -1) avail=\(Int(availableHeight))")
            if !newExpanded && viewModel.firstAvailableHeight == nil {
                viewModel.firstAvailableHeight = availableHeight
                print("🟡 [TaskListView] isFiltersExpanded collapse → captured firstAvail=\(Int(availableHeight))")
            }
            updateItemsPerPage()
        }
        #if DEBUG
        .overlay(
            VStack(alignment: .trailing, spacing: 2) {
                Text("avail: \(String(format: "%.0f", availableHeight))")
                Text("firstAvail: \(String(format: "%.0f", viewModel.firstAvailableHeight ?? availableHeight))")
                Text("median: \(String(format: "%.1f", lastMedian))")
                Text("rawFit: \(String(format: "%.2f", lastRawFit)) frac: \(String(format: "%.2f", lastFrac))")
                Text("usable: \(String(format: "%.0f", lastUsableHeight))")
                Text("items: \(lastComputedItems) filtered: \(viewModel.filteredTasksCache.count)")
                Text("pages: \(viewModel.totalPages) height: \(String(format: "%.0f", computedListHeight))")
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
        // When firstAvailableHeight hasn't been captured yet and filters are expanded,
        // availableHeight reflects the taller expanded window (~518px instead of ~378px).
        // Using it would set itemsPerPage too high (e.g. 8), swallowing all filtered tasks
        // into one page and hiding the pager. Wait until the non-expanded height is known.
        if viewModel.firstAvailableHeight == nil && isFiltersExpanded { return }

        let defaultRowHeight: CGFloat = 64.0
        let dividerThickness: CGFloat = 1.0

        let rowHeights = reportedRowHeights.isEmpty ? [defaultRowHeight] : reportedRowHeights
        let sorted = rowHeights.sorted()
        let median = sorted[sorted.count / 2]
        let displayRowHeight = (median.isFinite && median > 0) ? median : defaultRowHeight
        lastMedian = displayRowHeight

        guard availableHeight.isFinite && availableHeight > 0 else {
            let fallbackItems = max(1, Int(floor(500.0 / displayRowHeight)))
            if viewModel.itemsPerPage != fallbackItems {
                viewModel.itemsPerPage = fallbackItems
                viewModel.resetPagination()
            }
            computedListHeight = CGFloat(viewModel.itemsPerPage) * displayRowHeight
            return
        }

        // availableHeight is what SwiftUI allocated to TaskListView after the header and footer
        // siblings already claimed their space. Do NOT subtract them again.
        let usableHeightClamped = viewModel.firstAvailableHeight ?? availableHeight
        lastUsableHeight = usableHeightClamped

        // floor() ensures we never claim more items fit than the measured height allows.
        let rawFit = usableHeightClamped / displayRowHeight
        let computedItems = max(1, Int(floor(rawFit)))
        lastComputedItems = computedItems
        lastRawFit = rawFit
        lastFrac = rawFit - floor(rawFit)

        if viewModel.itemsPerPage != computedItems {
            viewModel.itemsPerPage = computedItems
            viewModel.resetPagination()
        }

        // Use the actual task count on the current page for height/stretch computation.
        // On the last page there may be fewer tasks than computedItems.
        let actualTasks = viewModel.paginatedTasks.count
        guard actualTasks > 0 else {
            computedListHeight = min(CGFloat(computedItems) * displayRowHeight, usableHeightClamped)
            perRowHeight = displayRowHeight
            return
        }

        let dividers = CGFloat(max(0, actualTasks - 1)) * dividerThickness
        let naturalContentHeight = CGFloat(actualTasks) * displayRowHeight + dividers
        let emptySpace = usableHeightClamped - naturalContentHeight

        // Stretch rows to fill the dead zone only when it is smaller than one row height.
        // A larger gap means the last page has noticeably fewer tasks — don't stretch there.
        if emptySpace > 0 && emptySpace < displayRowHeight {
            perRowHeight = (usableHeightClamped - dividers) / CGFloat(actualTasks)
            computedListHeight = usableHeightClamped
        } else {
            perRowHeight = displayRowHeight
            computedListHeight = min(naturalContentHeight, usableHeightClamped)
        }
    }
}

// PreferenceKey for row heights
struct RowHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
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