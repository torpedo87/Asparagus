//
//  LeftViewController.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 12..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import Action

class LeftViewController: UIViewController, BindableType {
  private let bag = DisposeBag()
  var viewModel: LeftViewModel!
  private lazy var topView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor(hex: "283A45")
    return view
  }()
  private lazy var settingButton: UIButton = {
    let btn = UIButton()
    btn.setImage(UIImage(named: "setting"), for: .normal)
    return btn
  }()
  
  private lazy var tableView: UITableView = {
    let view = UITableView()
    view.backgroundColor = UIColor.clear
    view.register(TagCell.self,
                  forCellReuseIdentifier: TagCell.reuseIdentifier)
    view.rowHeight = UIScreen.main.bounds.height / 15
    view.separatorStyle = .none
    view.delegate = self
    return view
  }()
  private lazy var authButton: UIButton = {
    let btn = UIButton()
    btn.imageView?.layer.cornerRadius = UIScreen.main.bounds.height / 30
    return btn
  }()
  private var dataSource: RxTableViewSectionedReloadDataSource<TagSection>!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
    configureDataSource()
  }
  
  func setupView() {
    view.backgroundColor = UIColor(hex: "283A45")
    topView.addSubview(authButton)
    topView.addSubview(settingButton)
    view.addSubview(topView)
    view.addSubview(tableView)
    topView.snp.makeConstraints { (make) in
      make.height.equalTo(UIScreen.main.bounds.height / 10)
      make.bottom.equalTo(tableView.snp.top)
      if #available(iOS 11.0, *) {
        make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
        make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
      } else {
        make.left.top.right.equalTo(view)
      }
    }
    authButton.snp.makeConstraints { (make) in
      make.width.height.equalTo(UIScreen.main.bounds.height / 15)
      make.centerY.equalTo(topView)
      make.left.equalTo(topView).offset(10)
    }
    settingButton.snp.makeConstraints { (make) in
      make.width.height.equalTo(UIScreen.main.bounds.height / 30)
      make.centerY.equalTo(topView)
      make.right.equalTo(topView).offset(-10)
    }
    tableView.snp.makeConstraints { (make) in
      if #available(iOS 11.0, *) {
        make.left.equalTo(view.safeAreaLayoutGuide.snp.left)
        make.right.equalTo(view.safeAreaLayoutGuide.snp.right)
        make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
      } else {
        make.left.right.bottom.equalTo(view)
      }
    }
  }
  
  func bindViewModel() {
    settingButton.rx.action = viewModel.goToSetting()
    authButton.rx.action = viewModel.onAuth()
    viewModel.sectionedItems
      .bind(to: tableView.rx.items(dataSource: dataSource))
      .disposed(by: bag)
    
    tableView.rx
      .modelSelected(Tag.self)
      .map({ (tag) -> String in
        return tag.title
      })
      .bind(to: viewModel.selectedGroupTitle)
      .disposed(by: bag)
    
    viewModel.isLoggedIn.asObservable()
      .subscribe(onNext: { [unowned self] bool in
        if bool {
          if let me = UserDefaults.loadUser(), let imgUrl = me.imgUrl {
            let imgData = try! Data(contentsOf: imgUrl)
            self.authButton.setImage(UIImage(data: imgData), for: .normal)
          }
        } else {
          self.authButton.setImage(UIImage(named: "user"), for: .normal)
        }
      })
      .disposed(by: bag)
  }
  
  func configureDataSource() {
    dataSource = RxTableViewSectionedReloadDataSource<TagSection> (
      configureCell: { dataSource, tableView, indexPath, item in
        let cell = tableView.dequeueReusableCell(withIdentifier: TagCell.reuseIdentifier,
                                                 for: indexPath) as! TagCell
        cell.configureCell(tag: item)
        return cell
      },
      titleForHeaderInSection: { dataSource, index in
        dataSource.sectionModels[index].header
    }
    )
  }
}

extension LeftViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView,
                 willDisplayHeaderView view: UIView,
                 forSection section: Int) {
    view.tintColor = UIColor(hex: "283A45")
    let header = view as! UITableViewHeaderFooterView
    header.textLabel?.textColor = UIColor.white
  }
}
