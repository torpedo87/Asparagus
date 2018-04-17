//
//  PopUpViewController.swift
//  Asparagus
//
//  Created by junwoo on 2018. 4. 15..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PopUpViewController: UIViewController, BindableType {
  private let bag = DisposeBag()
  var viewModel: EditViewModel!
  private lazy var segmentedControl: UISegmentedControl = {
    let view = UISegmentedControl(items: ["Assignees", "Tags", "GitHub"])
    view.selectedSegmentIndex = 0
    view.layer.cornerRadius = 10
    view.backgroundColor = UIColor.white
    view.tintColor = UIColor(hex: "283A45")
    return view
  }()
  private let pickerView: UIPickerView = {
    let view = UIPickerView()
    return view
  }()
  private lazy var repoView: UIView = {
    let view = UIView()
    view.layer.cornerRadius = 10
    return view
  }()
  private lazy var repoLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    label.layer.cornerRadius = 10
    label.backgroundColor = UIColor.white
    label.text = "Repository :"
    label.adjustsFontSizeToFitWidth = true
    return label
  }()
  private lazy var selectedRepositoryLabel: UILabel = {
    let label = UILabel()
    label.textAlignment = .center
    label.layer.cornerRadius = 10
    label.backgroundColor = UIColor.white
    return label
  }()
  private lazy var tagTableView: UITableView = {
    let view = UITableView()
    view.layer.cornerRadius = 10
    view.rowHeight = UIScreen.main.bounds.height / 15
    view.register(SubTagCell.self, forCellReuseIdentifier: SubTagCell.reuseIdentifier)
    view.register(NewTaskCell.self, forCellReuseIdentifier: NewTaskCell.reuseIdentifier)
    return view
  }()
  private lazy var baseView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.white
    view.layer.cornerRadius = 20
    return view
  }()
  private lazy var assigneeTableView: UITableView = {
    let view = UITableView()
    view.register(UITableViewCell.self, forCellReuseIdentifier: "TableViewCell")
    return view
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
  }
  
  func setupView() {
    view.backgroundColor = UIColor.black.withAlphaComponent(0.75)
    view.addSubview(baseView)
    baseView.addSubview(segmentedControl)
    baseView.addSubview(assigneeTableView)
    baseView.addSubview(repoView)
    repoView.addSubview(repoLabel)
    repoView.addSubview(selectedRepositoryLabel)
    repoView.addSubview(pickerView)
    baseView.addSubview(tagTableView)
    baseView.snp.makeConstraints { (make) in
      make.center.equalToSuperview()
      make.width.equalTo(UIScreen.main.bounds.width * 3 / 4)
      make.height.equalTo(UIScreen.main.bounds.height * 3 / 4)
    }
    segmentedControl.snp.makeConstraints { (make) in
      make.top.left.right.equalTo(baseView)
      make.height.equalTo(50)
    }
    assigneeTableView.snp.makeConstraints { (make) in
      make.left.bottom.right.equalTo(baseView)
      make.top.equalTo(segmentedControl.snp.bottom)
    }
    repoView.snp.makeConstraints { (make) in
      make.top.equalTo(segmentedControl.snp.bottom)
      make.left.right.equalTo(segmentedControl)
      make.bottom.equalTo(baseView)
    }
    tagTableView.snp.makeConstraints { (make) in
      make.top.equalTo(segmentedControl.snp.bottom)
      make.left.right.equalTo(segmentedControl)
      make.bottom.equalTo(baseView)
    }
    repoLabel.snp.makeConstraints { (make) in
      make.top.left.equalTo(repoView)
      make.height.equalTo(UIScreen.main.bounds.height / 20)
      make.width.equalTo(UIScreen.main.bounds.width / 3)
    }
    selectedRepositoryLabel.snp.makeConstraints { (make) in
      make.left.equalTo(repoLabel.snp.right)
      make.top.right.equalTo(repoView)
      make.height.equalTo(UIScreen.main.bounds.height / 20)
    }
    pickerView.snp.makeConstraints { (make) in
      make.top.equalTo(selectedRepositoryLabel.snp.bottom)
      make.left.right.bottom.equalTo(repoView)
    }
  }
  
  func bindViewModel() {
    view.rx.tapGesture { [unowned self] gestureRecognizer, delegate in
      gestureRecognizer.delegate = self
      }
      .skip(1)
      .throttle(0.5, scheduler: MainScheduler.instance)
      .subscribe(onNext: { [unowned self] _ in
        self.viewModel.dismissView()
      })
      .disposed(by: bag)
    
    viewModel.assignees()
      .bind(to: assigneeTableView.rx.items) {
        (tableView: UITableView, index: Int, element: User) in
        let cell = UITableViewCell(style: .default, reuseIdentifier: "TableViewCell")
        cell.textLabel?.text = element.name
        return cell
      }
      .disposed(by: bag)
    
    viewModel.tags()
      .subscribeOn(MainScheduler.instance)
      .bind(to: tagTableView.rx.items) { [unowned self]
        (tableView: UITableView, index: Int, item: Tag) in
        if index == 0 {
          let cell = NewTaskCell(style: .default, reuseIdentifier: NewTaskCell.reuseIdentifier)
          cell.configureNewTagCell(onUpdateTags: self.viewModel.onUpdateTags)
          return cell
        } else {
          let cell = SubTagCell(style: .default, reuseIdentifier: SubTagCell.reuseIdentifier)
          cell.configureCell(item: item, onUpdateTags: self.viewModel.onUpdateTags)
          return cell
        }
      }
      .disposed(by: bag)
    
    segmentedControl.rx.selectedSegmentIndex.asDriver()
      .drive(onNext: { [unowned self] index in
        self.switchTableViews(index: index)
      })
      .disposed(by: bag)

    viewModel.repoTitles
      .bind(to: pickerView.rx.itemTitles) { _, item in
        return "\(item)"
      }
      .disposed(by: bag)

    pickerView.isHidden = viewModel.task.isServerGeneratedType

    pickerView.rx.modelSelected(String.self)
      .map { [unowned self] models -> String in
        let repoTitle = models.first!
        self.viewModel.selectedRepoTitle.accept(repoTitle)
        return repoTitle
      }.bind(to: selectedRepositoryLabel.rx.text)
      .disposed(by: bag)

    if let repo = viewModel.task.repository {
      selectedRepositoryLabel.text = repo.name
    } else {
      selectedRepositoryLabel.text = ""
    }
  }
  
  func fadeView(view: UIView, hidden: Bool) {
    UIView.transition(with: view, duration: 0.5, options: [.transitionCrossDissolve], animations: {
      view.isHidden = hidden
    })
  }
  
  func switchTableViews(index: Int) {
    switch index {
    case 0: do {
      fadeView(view: repoView, hidden: true)
      fadeView(view: tagTableView, hidden: true)
      fadeView(view: assigneeTableView, hidden: false)
      }
    case 1: do {
      fadeView(view: repoView, hidden: true)
      fadeView(view: tagTableView, hidden: false)
      fadeView(view: assigneeTableView, hidden: true)
      }
    case 2: do {
      fadeView(view: repoView, hidden: false)
      fadeView(view: tagTableView, hidden: true)
      fadeView(view: assigneeTableView, hidden: true)
      }
    default: do {}
    }
  }
}

extension PopUpViewController: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    return touch.view == gestureRecognizer.view
  }
}
