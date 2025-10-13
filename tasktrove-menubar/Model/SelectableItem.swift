
import Foundation

protocol SelectableItem: Identifiable, Hashable {
	var id: String { get }
	var name: String { get }
	var color: String { get }
}
