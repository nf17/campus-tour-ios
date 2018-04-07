//
//  FeaturedViewController.swift
//  CampusTour
//
//  Created by Ji Hwan Seung on 3/18/18.
//  Copyright © 2018 cuappdev. All rights reserved.
//

import UIKit
import SnapKit

class FeaturedViewController: UIViewController, FilterFunctionsDelegate, PopupFilterProtocol {
    let itemFeedViewController = ItemFeedViewController()
    var filterBar: FilterBar!
    var arButton: UIBarButtonItem!
    let searchManager = ItemFeedSearchManager()
    
    //Replace with data from DataManager
    var popupViewController: PopupViewController!
    private var currentModalMode: Filter?
    private var filterBarCurrentStatus = FilterBarCurrentStatus(Filter.general.rawValue, Filter.date.rawValue)
    private var blackView: UIView!
    
    //for popupViewController
    private var isModal = false {
        didSet {
            if !isModal {
                popupViewController.view.isHidden = true
                blackView.isHidden = true
            } else {
                popupViewController.view.isHidden = false
                blackView.isHidden = false
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        extendedLayoutIncludesOpaqueBars = true
        
        self.definesPresentationContext = true
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        popupViewController = PopupViewController()
        popupViewController.delegate = self
        
        setTopNavBar()
        setBottomView()
        
        blackView = UIView(frame: view.bounds)
        blackView.backgroundColor = .black
        blackView.alpha = 0.3
        blackView.isHidden = true
        view.bringSubview(toFront: filterBar)
    }
    
    @IBAction func openARMode() {
        let popupViewController = ARExplorerViewController.withDefaultData()
        self.present(popupViewController, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        searchManager.attachTo(navigationItem: navigationItem)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        searchManager.detachFrom(navigationItem: navigationItem)
    }
    
    //Setup filter & search portion of ViewController
    func setTopNavBar() {
        searchManager.delgate = self
        searchManager.allData = testEvents as [Any] + testPlaces as [Any]
        
        arButton = UIBarButtonItem(title: "AR", style: .plain, target: self, action: #selector(openARMode))
        navigationItem.setRightBarButton(arButton, animated: false)
        
        filterBar = FilterBar()
        view.addSubview(filterBar)
        filterBar.snp.makeConstraints { (make) in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
    }
    
    //Setup Feed portion of ViewController
    func setBottomView() {
        addChildViewController(itemFeedViewController)
        
        //view.insertSubview(itemFeedViewController.view, belowSubview: searchResultsTableView)
        view.addSubview(itemFeedViewController.view)
        itemFeedViewController.view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        itemFeedViewController.didMove(toParentViewController: self)
    }
    
    func openPopupView(_ data: PopupData) {
        view.endEditing(true)
        if isModal {
            isModal = false
            self.filterBar.buttons.first?.setTitle(self.filterBarCurrentStatus.generalSelected, for: .normal)
            self.filterBar.buttons.last?.setTitle(self.filterBarCurrentStatus.dateSelected, for: .normal)
            searchManager.searchBar.becomeFirstResponder() //TODO encapsulate in searchManager
            return
        }
        popupViewController.resetVariables(status: filterBarCurrentStatus, filterMode: data.filterMode)
        popupViewController.data = data
        popupViewController.tableView.reloadData()
        
        view.bringSubview(toFront: popupViewController.view)
        
        var filterHeight = 0
        switch data.filterMode {
        case .general:
            filterHeight = min(320, 40*Tag.schoolFilters.count+20)
            filterBar.buttons.first?.bringSubview(toFront: blackView)
        case .date:
            filterHeight = min(320, 40*dateFilters.count+20)
            filterBar.buttons.first?.bringSubview(toFront: blackView)
        }
        
        popupViewController.view.snp.updateConstraints { (make) in
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.top.equalTo(filterBar.snp.bottom).offset(10)
            make.height.equalTo(filterHeight)
        }
        popupViewController.updateViewConstraints()
        popupViewController.view.becomeFirstResponder()
        searchManager.searchBar.resignFirstResponder()
        isModal = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touch called")
        guard let touch = touches.first else { return }
        print("iscalled")
        if isModal {
            let loc = touch.location(in: self.view)
            if !popupViewController.view.frame.contains(loc) {
                isModal = false
            }
        }
    }
    
    func updateFilterBar(_ status: FilterBarCurrentStatus) {
        filterBarCurrentStatus = status
    }

}

extension FeaturedViewController: ItemFeedSearchManagerDelegate {
    func didStartSearchMode() {
        print("START search")
        self.navigationItem.setRightBarButton(nil, animated: false)

        //Prepare filter viewcontroller
        addChildViewController(popupViewController)
        view.addSubview(popupViewController.view)
        isModal = false
        
        //Show filter bar
        filterBar.isHidden = false
        filterBar.snp.remakeConstraints { (make) in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        itemFeedViewController.view.snp.remakeConstraints { make in
            make.top.equalTo(filterBar.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
    func didFindSearchResults(results: ItemFeedSpec) {
        if self.searchManager.searchIsActive {
            self.itemFeedViewController.updateItems(newSpec: results)
        }
    }
    
    func didEndSearchMode() {
        print("END search")

        //remove filter bar
        self.filterBar.snp.remakeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.equalToSuperview()
            make.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
        itemFeedViewController.view.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        UIView.animate(
            withDuration: 0.5,
            animations: {self.view.layoutIfNeeded()},
            completion: {_ in self.filterBar.isHidden = true})
        
        //remove popup viewcontroller
        popupViewController.removeFromParentViewController()
        isModal = false
        filterBar.buttons.first?.setTitle(Filter.general.rawValue, for: .normal)
        filterBar.buttons.last?.setTitle(Filter.date.rawValue, for: .normal)
        
        self.navigationItem.setRightBarButton(arButton, animated: false)
        self.itemFeedViewController.updateItems(newSpec: ItemFeedSpec.testItemFeedSpec)
    }
}
