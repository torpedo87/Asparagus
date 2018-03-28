//
//  DetailViewController.swift
//  Asparagus
//
//  Created by junwoo on 2018. 3. 24..
//  Copyright © 2018년 samchon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxGesture
import RxDataSources

class DetailViewController: UIViewController, BindableType, GradientBgRepresentable {
  let transition = PopAnimator()
  private let bag = DisposeBag()
  var viewModel: DetailViewModel!
  var initialTouchPoint: CGPoint = CGPoint(x: 0,y: 0)
  
  private lazy var container: FoldableView = {
    let view = FoldableView()
    view.backgroundColor = UIColor.white
    view.layer.cornerRadius = 10
    view.layer.shadowColor = UIColor.darkGray.cgColor
    view.layer.shadowRadius = 15
    view.layer.shadowOpacity = 0.75
    return view
  }()
  private lazy var segmentedControl: UISegmentedControl = {
    let view = UISegmentedControl(items: ["Tags", "CheckList"])
    view.selectedSegmentIndex = 0
    view.backgroundColor = UIColor.white
    view.tintColor = UIColor.blue
    return view
  }()
  private lazy var tagTableView: UITableView = {
    let view = UITableView()
    view.backgroundColor = UIColor(hex: "4478E4")
    view.rowHeight = UIScreen.main.bounds.height / 15
    view.register(TagCell.self, forCellReuseIdentifier: TagCell.reuseIdentifier)
    view.register(NewTaskCell.self, forCellReuseIdentifier: NewTaskCell.reuseIdentifier)
    return view
  }()
  private lazy var checkListTableView: UITableView = {
    let view = UITableView()
    view.rowHeight = UIScreen.main.bounds.height / 15
    view.register(SubTaskCell.self, forCellReuseIdentifier: SubTaskCell.reuseIdentifier)
    view.register(NewTaskCell.self, forCellReuseIdentifier: NewTaskCell.reuseIdentifier)
    return view
  }()
  private let titleTextField: UITextField = {
    let view = UITextField()
    view.placeholder = "Please enter task title"
    view.layer.borderColor = UIColor.black.cgColor
    view.layer.borderWidth = 0.5
    return view
  }()
  
  private lazy var bodyTextView: UITextView = {
    let view = UITextView()
    view.layer.borderColor = UIColor.black.cgColor
    view.layer.borderWidth = 0.5
    view.text = "Please enter task body"
    view.textColor = UIColor.lightGray
    return view
  }()
  
  private var saveButton: UIButton = {
    let btn = UIButton()
    btn.setTitleColor(UIColor(hex: "4478E4"), for: .normal)
    btn.setTitleColor(UIColor.lightGray, for: .disabled)
    btn.setTitle("SAVE", for: .normal)
    return btn
  }()
  private var deleteButton: UIButton = {
    let btn = UIButton()
    btn.setTitleColor(UIColor(hex: "4478E4"), for: .normal)
    btn.setTitleColor(UIColor.lightGray, for: .disabled)
    btn.setTitle("DELETE", for: .normal)
    return btn
  }()
  private lazy var repositoryButton: UIButton = {
    let btn = UIButton()
    btn.setImage(UIImage(named: "repository"), for: .normal)
    return btn
  }()
  private lazy var tagButton: UIButton = {
    let btn = UIButton()
    btn.setImage(UIImage(named: "tag"), for: .normal)
    return btn
  }()
  private lazy var subTaskButton: UIButton = {
    let btn = UIButton()
    btn.setImage(UIImage(named: "list"), for: .normal)
    return btn
  }()
  private lazy var buttonStackView: UIStackView = {
    let view = UIStackView()
    view.axis = .horizontal
    view.spacing = 5
    view.distribution = .fillEqually
    return view
  }()
  private lazy var tempView: UIView = {
    let view = UIView()
    view.isHidden = true
    return view
  }()
  var dataSource: RxTableViewSectionedReloadDataSource<SubTaskSection>!
  override func viewDidLoad() {
    super.viewDidLoad()
    setGradientBgColor()
    setupView()
    configureDataSource()
    titleTextField.becomeFirstResponder()
  }
  
  func setupView() {
    title = "Detail"
    view.addSubview(container)
    container.addSubview(saveButton)
    container.addSubview(titleTextField)
    container.addSubview(bodyTextView)
    container.addSubview(tempView)
    tempView.addSubview(segmentedControl)
    tempView.addSubview(tagTableView)
    tempView.addSubview(checkListTableView)
    buttonStackView.addArrangedSubview(repositoryButton)
    buttonStackView.addArrangedSubview(tagButton)
    buttonStackView.addArrangedSubview(subTaskButton)
    container.addSubview(buttonStackView)
    container.snp.makeConstraints { (make) in
      make.center.equalToSuperview()
      make.width.equalTo(UIScreen.main.bounds.width * 3 / 4)
      make.height.equalTo(UIScreen.main.bounds.height / 3)
    }
    
    saveButton.snp.makeConstraints { (make) in
      saveButton.sizeToFit()
      make.top.equalTo(container.snp.top).offset(10)
      make.right.equalTo(container.snp.right).offset(-10)
    }
    titleTextField.snp.makeConstraints { (make) in
      make.top.equalTo(saveButton.snp.bottom).offset(10)
      make.centerX.equalToSuperview()
      make.width.equalTo(UIScreen.main.bounds.width * 3 / 5)
      make.height.equalTo(50)
    }
    bodyTextView.snp.makeConstraints { (make) in
      make.top.equalTo(titleTextField.snp.bottom).offset(10)
      make.centerX.equalToSuperview()
      make.width.equalTo(UIScreen.main.bounds.width * 3 / 5)
      make.height.equalTo(UIScreen.main.bounds.height / 7)
    }
    
    tempView.snp.makeConstraints { (make) in
      make.top.equalTo(bodyTextView.snp.bottom).offset(10)
      make.centerX.equalToSuperview()
      make.width.equalTo(UIScreen.main.bounds.width * 3 / 5)
      make.bottom.equalTo(buttonStackView.snp.top).offset(-10)
    }
    segmentedControl.snp.makeConstraints { (make) in
      make.left.top.right.equalTo(tempView)
    }
    tagTableView.snp.makeConstraints { (make) in
      make.top.equalTo(segmentedControl.snp.bottom).offset(5)
      make.left.bottom.right.equalTo(tempView)
    }
    checkListTableView.snp.makeConstraints { (make) in
      make.top.equalTo(segmentedControl.snp.bottom).offset(5)
      make.left.bottom.right.equalTo(tempView)
    }
    buttonStackView.snp.makeConstraints { (make) in
      make.right.equalTo(container.snp.right).offset(-10)
      make.bottom.equalTo(container.snp.bottom).offset(-10)
    }
  }
  
  func toggleSubViews() {
    if tempView.isHidden {
      fadeView(view: tempView, hidden: false)
    } else {
      fadeView(view: tempView, hidden: false)
    }
  }
  
  func toggleTableViews(index: Int) {
    if index == 0 {
      fadeView(view: tagTableView, hidden: false)
      fadeView(view: checkListTableView, hidden: true)
    } else {
      fadeView(view: tagTableView, hidden: true)
      fadeView(view: checkListTableView, hidden: false)
    }
  }
  
  func fadeView(view: UIView, hidden: Bool) {
    UIView.transition(with: view, duration: 0.5, options: [.transitionCrossDissolve], animations: {
      view.isHidden = hidden
    })
  }
  
  func bindViewModel() {
    viewModel.tags()
      .bind(to: tagTableView.rx.items) { [unowned self]
        (tableView: UITableView, index: Int, item: Tag) in
        if index == 0 {
          let cell = NewTaskCell(style: .default, reuseIdentifier: NewTaskCell.reuseIdentifier)
          cell.configureNewTagCell(vm: self.viewModel)
          return cell
        } else {
          let cell = TagCell(style: .default, reuseIdentifier: TagCell.reuseIdentifier)
          cell.configureCell(tag: item)
          return cell
        }
      }
      .disposed(by: bag)
    
    segmentedControl.rx.selectedSegmentIndex.asDriver()
      .drive(onNext: { [unowned self] index in
        self.toggleTableViews(index: index)
      })
      .disposed(by: bag)
    
    repositoryButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .asDriver(onErrorJustReturn: ())
      .drive(onNext: { [unowned self] _ in
        self.container.toggle()
        self.toggleSubViews()
      })
      .disposed(by: bag)
    
    titleTextField.rx.text.orEmpty
      .map { title -> Bool in
        return !title.isEmpty
      }.bind(to: saveButton.rx.isEnabled)
      .disposed(by: bag)
    
    titleTextField.text = viewModel.task.title
    bodyTextView.text = viewModel.task.body
    
    saveButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .map({ [unowned self] _ -> (String, String) in
        let title = self.titleTextField.text ?? ""
        let body = self.bodyTextView.text ?? ""
        return (title, body)
      }).bind(to: viewModel.onUpdateBodyTitle.inputs)
      .disposed(by: bag)
    
    deleteButton.rx.tap
      .throttle(0.5, scheduler: MainScheduler.instance)
      .map { [unowned self] _ -> TaskItem in
        return self.viewModel.task
      }.bind(to: viewModel.onDelete.inputs)
      .disposed(by: bag)
    
    view.rx.tapGesture()
      .when(UIGestureRecognizerState.recognized)
      .subscribe(onNext: { [unowned self] _ in
        self.view.endEditing(true)
      })
      .disposed(by: bag)
    
    deleteButton.isEnabled = !viewModel.task.isServerGeneratedType
    
    view.rx.panGesture().asObservable()
      .subscribe(onNext: { [unowned self] recognizer in
        let touchPoint = recognizer.location(in: self.view.window)
        if recognizer.state == UIGestureRecognizerState.began {
          self.initialTouchPoint = touchPoint
        } else if recognizer.state == UIGestureRecognizerState.changed {
          if touchPoint.y - self.initialTouchPoint.y > 0 {

            self.view.frame = CGRect(x: 0, y: touchPoint.y - self.initialTouchPoint.y, width: self.view.frame.size.width, height: self.view.frame.size.height)
          }
        } else if recognizer.state == UIGestureRecognizerState.ended || recognizer.state == UIGestureRecognizerState.cancelled {
          if touchPoint.y - self.initialTouchPoint.y > 100 {
            self.viewModel.pop()
          } else {
            UIView.animate(withDuration: 0.3, animations: {
              self.view.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
            })
          }
        }
      })
      .disposed(by: bag)
    
    viewModel.sectionedItems
      .bind(to: checkListTableView.rx.items(dataSource: dataSource))
      .disposed(by: bag)
  }
  
  func configureDataSource() {
    dataSource = RxTableViewSectionedReloadDataSource<SubTaskSection>(
      configureCell: { [unowned self] (dataSource, tableView, indexPath, item) in
        switch indexPath.section {
        case 0: do {
          guard let cell = tableView.dequeueReusableCell(withIdentifier: NewTaskCell.reuseIdentifier)
            as? NewTaskCell else { return NewTaskCell() }
          cell.configureCell(vm: self.viewModel)
          return cell
          }
        default: do {
          guard let cell = tableView.dequeueReusableCell(withIdentifier: SubTaskCell.reuseIdentifier)
            as? SubTaskCell else { return TaskCell() }
          cell.configureCell(item: item, action: self.viewModel.onToggle(task: item))
          return cell
        }
        }
    },
      titleForHeaderInSection: { dataSource, sectionIndex in
        return dataSource[sectionIndex].header
    }
    )
  }
  
}
