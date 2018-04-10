//
//  SettingViewController.swift
//  Asparagus
//
//  Created by junwoo on 2018. 4. 10..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import Action

class SettingViewController: UIViewController, BindableType {
  private let bag = DisposeBag()
  var viewModel: SettingViewModel!
  private let tableView: UITableView = {
    let view = UITableView(frame: CGRect.zero, style: .grouped)
    view.rowHeight = UIScreen.main.bounds.height / 15
    view.register(UITableViewCell.self, forCellReuseIdentifier: "TableViewCell")
    view.sectionHeaderHeight = UIScreen.main.bounds.height / 30
    return view
  }()
  
  private lazy var closeBarButton: UIBarButtonItem = {
    let item = UIBarButtonItem(title: "CLOSE",
                               style: .plain,
                               target: self,
                               action: nil)
    return item
  }()
  var dataSource: RxTableViewSectionedReloadDataSource<SettingSection>!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    configureDataSource()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.navigationController?.isNavigationBarHidden = false
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    self.navigationController?.isNavigationBarHidden = true
  }
  
  func setupView() {
    title = "Setting"
    navigationItem.leftBarButtonItem = closeBarButton
    view.addSubview(tableView)
    
    tableView.snp.makeConstraints { (make) in
      if #available(iOS 11.0, *) {
        make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
        make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
        make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
      } else {
        make.edges.equalTo(view)
      }
    }
  }
  
  func bindViewModel() {
    closeBarButton.rx.action = viewModel.dismissView()
    
    viewModel.sectionedItems
      .bind(to: tableView.rx.items(dataSource: dataSource))
      .disposed(by: bag)
    
    tableView.rx.itemSelected
      .do(onNext: { [unowned self] indexPath in
        self.tableView.deselectRow(at: indexPath, animated: false)
      })
      .map { [unowned self] indexPath in
        try! self.dataSource.model(at: indexPath) as! SettingModel
      }
      .subscribe(onNext: { [unowned self] model in
        switch model {
        case .text(_): do {
          self.viewModel.onAuth()
          }
        case .license(let license): do {
          self.viewModel.goToLicenseUrl(urlString: license.licenseUrl())
          }
        }
      })
      .disposed(by: bag)
  }
  
  func configureDataSource() {
    dataSource = RxTableViewSectionedReloadDataSource<SettingSection>(
      configureCell: { (dataSource, tableView, indexPath, item) in
        switch item {
        case .text(let string):
          if let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell") {
            cell.textLabel?.text = string
            return cell
          }
          return UITableViewCell()
        case .license(let license):
          if let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell") {
            cell.textLabel?.text = license.rawValue
            return cell
          }
          return UITableViewCell()
        }
      },
      titleForHeaderInSection: { dataSource, sectionIndex in
        return dataSource[sectionIndex].header
    }
    )
  }
}
