import SwiftUI
import UIKit

/// UIKit supplies the physical curl, including a center binding for two-page spreads.
struct PassportPageCurl<Page: View>: UIViewControllerRepresentable {
    @Binding var leaf: Int
    let spread: Bool
    let reduceMotion: Bool
    let count: Int
    @ViewBuilder var page: (Int) -> Page

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let controller = UIPageViewController(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: [.spineLocation: NSNumber(value: (spread ? UIPageViewController.SpineLocation.mid : .min).rawValue)]
        )
        controller.isDoubleSided = spread
        controller.view.backgroundColor = UIColor(red: 244 / 255, green: 238 / 255, blue: 220 / 255, alpha: 1)
        controller.delegate = context.coordinator
        controller.dataSource = reduceMotion ? nil : context.coordinator
        controller.setViewControllers(context.coordinator.visiblePages(startingAt: normalizedLeaf), direction: .forward, animated: false)
        return controller
    }

    private var normalizedLeaf: Int { spread ? leaf / 2 * 2 : leaf }

    func updateUIViewController(_ controller: UIPageViewController, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        controller.dataSource = reduceMotion ? nil : coordinator
        guard !coordinator.isTurning else { return }
        for (index, host) in coordinator.hosts { host.rootView = page(index) }
        coordinator.displayRequestedPages(in: controller)
    }

    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: PassportPageCurl
        var hosts: [Int: LeafHost<Page>] = [:]
        var isTurning = false

        init(_ parent: PassportPageCurl) { self.parent = parent }

        func host(_ number: Int) -> LeafHost<Page>? {
            guard (0..<parent.count).contains(number) else { return nil }
            if let existing = hosts[number] { return existing }
            let host = LeafHost(number: number, rootView: parent.page(number))
            hosts[number] = host
            return host
        }

        func visiblePages(startingAt number: Int) -> [UIViewController] {
            let range = parent.spread ? number..<(number + 2) : number..<(number + 1)
            return range.compactMap { host($0) }
        }

        func displayRequestedPages(in controller: UIPageViewController) {
            guard !isTurning else { return }
            let desired = parent.normalizedLeaf
            let current = (controller.viewControllers?.first as? LeafHost<Page>)?.number ?? 0
            guard current != desired else { return }
            isTurning = true
            controller.setViewControllers(visiblePages(startingAt: desired), direction: desired > current ? .forward : .reverse, animated: !parent.reduceMotion) { [weak self, weak controller] _ in
                guard let self, let controller else { return }
                self.isTurning = false
                // Honor a later edge tap that arrived while the current sheet was turning.
                self.displayRequestedPages(in: controller)
            }
        }

        func pageViewController(_ controller: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
            guard let current = viewController as? LeafHost<Page> else { return nil }
            return host(current.number - 1)
        }

        func pageViewController(_ controller: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
            guard let current = viewController as? LeafHost<Page> else { return nil }
            return host(current.number + 1)
        }

        func pageViewController(_ controller: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) { isTurning = true }

        func pageViewController(_ controller: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
            isTurning = false
            if completed, let first = controller.viewControllers?.first as? LeafHost<Page> {
                parent.leaf = parent.spread ? first.number / 2 * 2 : first.number
            }
        }
    }
}

final class LeafHost<Content: View>: UIHostingController<Content> {
    let number: Int

    init(number: Int, rootView: Content) {
        self.number = number
        super.init(rootView: rootView)
        safeAreaRegions = []
        view.backgroundColor = UIColor(red: 244 / 255, green: 238 / 255, blue: 220 / 255, alpha: 1)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) { fatalError("Storyboard initialization is unsupported") }
}
