//
//  MainViewController.swift
//  ThriftStoreLocator
//
//  Created by Gary Shirk on 2/20/17.
//  Copyright © 2017 Gary Shirk. All rights reserved.
//

import UIKit
import MapKit
import SideMenu

// TODO - MapView initial height should be proportional to device height

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, MKMapViewDelegate, StoresViewModelDelegate {
    
//    var stores: [String] = ["Goodwill", "Salvation Army", "Savers", "Thrift on Main", "Sparrows Nest",
//                            "Goodwill Schaumburg", "Goodwill2", "Salvation Army2", "Savers2",
//                            "Thrift on Main2", "Sparrows Nest2", "Goodwill Crystal Lake",
//                            "Thrift on Main3", "Sparrows Nest3", "Goodwill Carpentersville",
//                            "Thrift on Main4", "Sparrows Nest4", "Goodwill Lake Zurich"]
    
    var viewModel: StoresViewModel!
    
    var searchedStores: [String] = []
    
    var selectedStore: String!
    
    var isSearching: Bool = false
    
    var titleBackgroundColor: UIColor!
    
    var previousScrollViewOffset: CGFloat = 0.0
    
    var barButtonDefaultTintColor: UIColor?

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var menuBarButton: UIBarButtonItem!
    @IBOutlet weak var searchBarButton: UIBarButtonItem!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var mapViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var mapViewYConstraint: NSLayoutConstraint!
    
    // TODO - Move dimmerView to front of view on storyboard. Keeping it behind tableView during development
    @IBOutlet weak var dimmerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Back", style:.plain, target:nil, action:nil)
        
        // Uncomment the following to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        

        // Side Menu appearance and configuration
        //let appDelegate = UIApplication.shared.delegate as! AppDelegate
        //SideMenuManager.menuAnimationBackgroundColor = appDelegate.uicolorFromHex(rgbValue: UInt32(AppDelegate.NAV_BAR_TINT_COLOR))
        SideMenuManager.menuAnimationBackgroundColor = UIColor.white
        SideMenuManager.menuFadeStatusBar = false
        SideMenuManager.menuAnimationTransformScaleFactor = 1.0
        SideMenuManager.menuPresentMode = .menuSlideIn
        
        // Scroll view inset adjustment handled by tableView constraints in storyboard
        self.automaticallyAdjustsScrollViewInsets = false
        
        // Search and Title configuration
        //titleLabel.tintColor = UIColor.white
        titleBackgroundColor = searchView.backgroundColor
        titleLabel.text = "Thrift Store Locator"
        barButtonDefaultTintColor = self.view.tintColor
        
        setSearchEditMode(doSet: false)
        setSearchEnabledMode(doSet: false)
        searchTextField.delegate = self
        
        // Map Kit View
        mapView.mapType = .standard
        mapView.delegate = self
        
        // Get list of stores for current location
        // TODO - Use dependency injection for setting viewModel
        viewModel = StoresViewModel(delegate: self, withLoadStores: true)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.isUserInteractionEnabled = true
        
        // DEBUG
        // print(mapViewYConstraint.constant)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func handleStoresUpdated(stores: [Store]) {
        tableView.reloadData()
    }
        
    // NOTE: Search bar tutorial json task from http://sweettutos.com/2015/12/26/hands-on-uisearchcontroller-the-complete-guide/
    // But below is old Swift code; Swift 3 updated code is in next function and is working https://grokswift.com/updating-nsurlsession-to-swift-3-0/
//    func retrieveFakeData() {
//        let session = URLSession.shared
//        let url:NSURL! = NSURL(string: "http://jsonplaceholder.typicode.com/users")
//    
//       
//        let task = session.downloadTaskWithURL(url as URL) { (location: NSURL?, response: URLResponse?, error: NSError?) -> Void in
//            if (location != nil){
//                let data:NSData! = NSData(contentsOfURL: location!)
//                do{
//                    self.users = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves) as! [[String : AnyObject]]
//                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                        self.tableView.reloadData()
//                    })
//                }catch{
//                    // Catch any exception
//                    print("Something went wrong")
//                }
//            }else{
//                // Error
//                print("An error occurred \(error)")
//            }
//        }
//        // Start the download task
//        task.resume()
//    }
    
    // OLD code - Moved to NetworkLayer and now using Alamofire
    func makeGetCall() {
        // Set up URL request
        let urlString: String = "http://jsonplaceholder.typicode.com/todos/1" // note: this is a test url
        guard let url = URL(string: urlString) else {
            print("Error: cannot create URL")
            return
        }
        let urlRequest = URLRequest(url: url)
        
        // Set up session
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        // Make the request
        let task = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
            
            // Handle returned response
            print(error ?? "no error")
            print(response!)
            
            // Parse the Json response data
            do {
                guard let todo = try JSONSerialization.jsonObject(with: data!, options: []) as? [String: Any] else {
                    print("Error trying to convert data to JSON")
                    return
                }
                
                // Got the data
                print("Data is \(todo.description)")
                
                // Reload the tableView on the main thread
                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.reloadData()
                })
                
                // todo object is a dictionary, so can access the title using the "title" key
                guard let todoTitle = todo["title"] as? String else {
                    print("Could not get title from JSON")
                    return
                }
                print("The title is: \(todoTitle)")
            } catch {
                print("Error trying to convert data to JSON")
                return
            }
        })
        task.resume()
    }

    //    func makeGetCall() {
    //        // Set up URL request
    //        let todoEndpoint: String = "http://jsonplaceholder.typicode.com/users"
    //        guard let url = URL(string: todoEndpoint) else {
    //            print("Error: cannot create URL")
    //            return
    //        }
    //        let urlRequest = URLRequest(url: url)
    //
    //        // Set up session
    //        let config = URLSessionConfiguration.default
    //        let session = URLSession(configuration: config)
    //
    //        // Make the request
    //        let task = session.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
    //            // Handle returned response
    //            print(error ?? "no error")
    //            print(response!)
    //        })
    //        task.resume()
    //    }

 
    // MARK: - TextField delegates
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        setSearchEditMode(doSet: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        setSearchEditMode(doSet: false)
        searchTextField.resignFirstResponder()
        return true
    }
    
    // May be called if forced even if shouldEndEditing returns NO (e.g. view removed from window) or endEditing:YES called
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let searchStr = searchTextField.text {
            searchedStores.removeAll()
            for store in viewModel.stores {
                if let storeStr = store.name {
                    if searchStr.isEmpty || (storeStr.localizedCaseInsensitiveContains(searchStr)) {
                        searchedStores.append(storeStr)
                    }
                }
            }
        }
        tableView.reloadData()
    }
    
    func setSearchEnabledMode(doSet setToEnabled: Bool) {
        if setToEnabled {
            isSearching = true
            setSearchEditMode(doSet: true)
            searchView.backgroundColor = UIColor.white
            titleLabel.isHidden = true
            searchTextField.isHidden = false
            searchTextField.becomeFirstResponder()
        } else {
            isSearching = false
            setSearchEditMode(doSet: false)
            searchView.backgroundColor = titleBackgroundColor
            titleLabel.isHidden = false
            searchTextField.isHidden = true
            searchTextField.text = ""
            searchTextField.resignFirstResponder()
            tableView.reloadData()
        }
    }
    
    func setSearchEditMode(doSet setToEdit: Bool) {
        if setToEdit {
            dimmerView.isHidden = false
            tableView.isUserInteractionEnabled = false
        } else {
            dimmerView.isHidden = true
            tableView.isUserInteractionEnabled = true
        }
    }
    
    @IBAction func searchButtonPressed(_ sender: Any) {
        print("search button pressed")
        
        if isSearching {
            setSearchEnabledMode(doSet: false)
        } else {
            setSearchEnabledMode(doSet: true)
        }
    }
    
    // MARK - ScrollView
    
    func restoreNavigationBar() {
        mapViewYConstraint.constant = 0.0
        var frame = self.navigationController?.navigationBar.frame
        frame?.origin.y = 20
        self.navigationController?.navigationBar.frame = frame!
        searchView.alpha = 1.0
        searchBarButton.isEnabled = true
        searchBarButton.tintColor = barButtonDefaultTintColor
        menuBarButton.isEnabled = true
        menuBarButton.tintColor = barButtonDefaultTintColor
    }
    
    func updateBarButtonItems(alpha: CGFloat) {
        searchView.alpha = alpha
        if alpha < 0.5 {
            searchBarButton.isEnabled = false
            searchBarButton.tintColor = UIColor.clear
            menuBarButton.isEnabled = false
            menuBarButton.tintColor = UIColor.clear
        } else {
            searchBarButton.isEnabled = true
            searchBarButton.tintColor = barButtonDefaultTintColor
            menuBarButton.isEnabled = true
            menuBarButton.tintColor = barButtonDefaultTintColor
        }
    }
    
    // TODO - This code came with sample code to hide nav bar when scrolling
    // Purpose was to animate the nav bar title to and from 1 -> 0 alpha,
    // But that seems to be happening even though this code is commented out
    
//    func stoppedScrolling() {
//        if let frame = self.navigationController?.navigationBar.frame {
//            if frame.origin.y < 20 {
//                animateNavBarTo(y: -(frame.size.height - 21))
//            }
//        }
//    }

    
//    func animateNavBarTo(y: CGFloat) {
//        UIView.animate(withDuration: 0.2, animations: {
//            if var frame = self.navigationController?.navigationBar.frame {
//                let alpha: CGFloat = frame.origin.y >= y ? 0.0 : 1.0
//                frame.origin.y = y
//                self.navigationController?.navigationBar.frame = frame
//                self.updateBarButtonItems(alpha: alpha)
//            }
//        })
//    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            //stoppedScrolling()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if var frame = self.navigationController?.navigationBar.frame {
            let navHeightMinus21 = (frame.size.height) - 21
            let scrollOffset = scrollView.contentOffset.y
            let scrollDiff = scrollOffset - self.previousScrollViewOffset
            let scrollHeight = scrollView.frame.size.height
            let scrollContentSizeHeight = scrollView.contentSize.height + scrollView.contentInset.bottom
            
            if scrollOffset <= -scrollView.contentInset.top {
                frame.origin.y = 20
                //print("scrollOffset <= -scrollview: Nav bar should show")
                
            } else if ((scrollOffset + scrollHeight) >= scrollContentSizeHeight) {
                frame.origin.y = -navHeightMinus21
                //print("scrollOffset <+ scrollHeight >= -scrollContentSizeHeight: Nav bar should hide")
                
            } else {
                frame.origin.y = min(20, max(-navHeightMinus21, frame.origin.y - scrollDiff))
                //print("else clause: Nav bar should be moving")
            }
            
            let framePercentageHidden = (( 20 - (frame.origin.y)) / ((frame.size.height) - 1))
            updateBarButtonItems(alpha: 1.0 - framePercentageHidden)
            
            self.navigationController?.navigationBar.frame = frame
            self.previousScrollViewOffset = scrollOffset
            
            mapViewYConstraint.constant = frame.origin.y - 20
            
            // DEBUG
//            print("navBarY = \(frame.origin.y), mapViewY = \(mapViewYConstraint.constant)")
//            print("navHeightMinus21: \(navHeightMinus21)")
//            print("Alpha: \(1.0 - framePercentageHidden)")
//            print("scrollOffset: \(scrollOffset)")
//            print("scrollDiff: \(scrollDiff)")
//            print("scrollHeight: \(scrollHeight)")
//            print("scrollView.contentSize.ht: \(scrollView.contentSize.height)")
//            print("scrollView.contentInsetBottom: \(scrollView.contentInset.bottom)")
//            print("scrollContentSize: \(scrollContentSizeHeight)")
//            print("=====")
            
            // TODO - This code shrinks and grows map view as user scrolls, but needs to be smoother
//            if (frame.origin.y == -size) && (mapViewHeightConstraint.constant >= 100) {
//                mapViewHeightConstraint.constant = mapViewHeightConstraint.constant - 10
//            }
//            else if (frame.origin.y == 20) && (mapViewHeightConstraint.constant <= 200.0) {
//                mapViewHeightConstraint.constant = mapViewHeightConstraint.constant + 10
//            }
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {

    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
    }
    
    // MARK: - Table view data source and delegates
    
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let v = UIView()
//        v.backgroundColor = .blue
//        let segmentedControl = UISegmentedControl(frame: CGRect(x: 10, y: 5, width: tableView.frame.width - 20, height: 30))
//        segmentedControl.insertSegment(withTitle: "One", at: 0, animated: false)
//        segmentedControl.insertSegment(withTitle: "Two", at: 1, animated: false)
//        segmentedControl.insertSegment(withTitle: "Three", at: 2, animated: false)
//        v.addSubview(segmentedControl)
//        return v
//    }
//    
//    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return mapViewHeight
//    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        guard let viewModel = viewModel else {
            return 0 }
        
        if isSearching {
            return searchedStores.count
        } else {
            return viewModel.stores.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "storeCell", for: indexPath)
        
        if isSearching {
            cell.textLabel?.text = searchedStores[indexPath.row]
        } else {
            cell.textLabel?.text = viewModel.stores[indexPath.row].name
        }
        
        return cell
        
    
//        let cell = tableView.dequeueReusableCell(withIdentifier: "storeCell", for: indexPath)
//        
//        if isSearching {
//            cell.textLabel?.text = searchedStores[indexPath.row]
//        } else {
//            cell.textLabel?.text = stores[indexPath.row]
//        }
//
//        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showStoreDetail" {
            
            // If navigation bar was hidden due to scrolling, restore it before seguing
            restoreNavigationBar()
            
            if let indexPath = tableView.indexPathForSelectedRow {
                
                if isSearching {
                    selectedStore = searchedStores[(indexPath.row)]
                } else {
                    selectedStore = viewModel.stores[(indexPath.row)].name
                }
            }
            
            let tabBarController = segue.destination as! UITabBarController
            tabBarController.navigationItem.title = selectedStore
            
            let detailNavigationController = tabBarController.viewControllers!.first as! UINavigationController
            let detailViewController = detailNavigationController.viewControllers.first as! DetailViewController
            detailViewController.labelString = selectedStore + " in Detail view"
            
            let mapNavigationController = tabBarController.viewControllers?[1] as! UINavigationController
            let mapViewController = mapNavigationController.viewControllers.first as! MapViewController
            mapViewController.labelString = selectedStore + " in Map view"
            
            print("Selected Store: \(selectedStore)")
        }
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
