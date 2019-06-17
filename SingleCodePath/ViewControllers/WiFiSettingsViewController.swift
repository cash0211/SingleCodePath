/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Mimics the Settings.app for displaying a dynamic list of available wi-fi access points
*/

import UIKit

// MARK: WiFiSettingsListSection

class WiFiSettingsListSection {
    var items: [WiFiSettingsViewController.Item] = []

    weak var viewController: WiFiSettingsViewController?

    init(with viewController: WiFiSettingsViewController) {
        self.viewController = viewController
    }
}

extension WiFiSettingsListSection : ListSectionProtocol {

    func numberOfItems() -> Int {
        return items.count
    }

    func cellForRow(_ context: ListGodContext, at indexPath: IndexPath) -> UITableViewCell {
        let cell = context.dequeueReusableCell(of: UITableViewCell.self, at: indexPath)
        configureCell(cell, at: indexPath)
        return cell
    }

    func configureCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        let item = items[indexPath.row]

        if item.isNetwork {
            cell.textLabel?.text = item.title
            cell.accessoryType = .detailDisclosureButton
            cell.accessoryView = nil
        } else if item.isConfig {
            cell.textLabel?.text = item.title
            if item.type == .wifiEnabled {
                let enableWifiSwitch = UISwitch()
                if let vc = viewController {
                    enableWifiSwitch.isOn = vc.wifiController.wifiEnabled
                    enableWifiSwitch.addTarget(self, action: #selector(vc.toggleWifi(_:)), for: .touchUpInside)
                }
                cell.accessoryView = enableWifiSwitch
            } else {
                cell.accessoryView = nil
                cell.accessoryType = .detailDisclosureButton
            }
        } else {
            fatalError("Unknown item type!")
        }
    }

    @objc
    func toggleWifi(_ wifiEnabledSwitch: UISwitch) {
        print(#function)
    }

    func didUpdate(to data: Any) {
        guard let items = data as? [WiFiSettingsViewController.Item] else {
            return
        }
        self.items = items
    }
}

// MARK: WiFiSettingsViewController

final class WiFiSettingsViewController: UIViewController {

    enum Section: CaseIterable {
        case config, networks
    }

    enum ItemType {
        case wifiEnabled, currentNetwork, availableNetwork
    }

    struct Item: Hashable, ListDiffable {
        let title: String
        let type: ItemType
        let network: WIFIController.Network?

        init(title: String, type: ItemType) {
            self.title = title
            self.type = type
            self.network = nil
            self.identifier = UUID()
        }
        init(network: WIFIController.Network) {
            self.title = network.name
            self.type = .availableNetwork
            self.network = network
            self.identifier = network.identifier
        }
        var isConfig: Bool {
            let configItems: [ItemType] = [.currentNetwork, .wifiEnabled]
            return configItems.contains(type)
        }
        var isNetwork: Bool {
            return type == .availableNetwork
        }

        private let identifier: UUID
        func hash(into hasher: inout Hasher) {
            hasher.combine(self.identifier)
        }

        var diffIdentifier: String {
            return "\(identifier)"
        }

        func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
            guard let o = object as? Item else {
                return false
            }
            return self == o
        }
    }

    let tableView = UITableView(frame: .zero, style: .grouped)
    var wifiController: WIFIController! = nil
    lazy var configurationMetadataItems: [Item] = {
        return [Item(title: "Wi-Fi", type: .wifiEnabled),
                Item(title: "breeno-net", type: .currentNetwork)]
    }()
    lazy var configurationItems: [Item] = []
    lazy var networkItems: [Item] = []

    lazy var listGod = ListGod()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Wi-Fi"
        configureTableView()
        configureDataSource()
        updateUI(animated: false)
    }
}

extension WiFiSettingsViewController {

    func configureDataSource() {
        wifiController = WIFIController { [weak self] (controller: WIFIController) in
            guard let self = self else { return }
            self.updateUI()
        }
        wifiController.scanForNetworks = true

        listGod.tableView = tableView
        listGod.dataSource = self
    }

    func updateUI(animated: Bool = true) {
        guard let controller = self.wifiController else { return }

        configurationItems = configurationMetadataItems.filter { !($0.type == .currentNetwork && !controller.wifiEnabled) }

        networkItems = []
        if controller.wifiEnabled {
            let sortedNetworks = controller.availableNetworks.sorted { $0.name < $1.name }
            networkItems = sortedNetworks.map { Item(network: $0) }
        }

        listGod.reloadDiffableData()
    }
}

extension WiFiSettingsViewController {

    func configureTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
    }

    @objc
    func toggleWifi(_ wifiEnabledSwitch: UISwitch) {
        wifiController.wifiEnabled = wifiEnabledSwitch.isOn
        updateUI()
    }
}

extension WiFiSettingsViewController : ListGodDataSource {
    func data(for listGod: ListGod) -> [ListDiffable] {
        return [configurationItems, networkItems]
    }

    func listGod(_ listGod: ListGod, section: Int) -> ListSectionProtocol {
        return WiFiSettingsListSection(with: self)
    }
}
