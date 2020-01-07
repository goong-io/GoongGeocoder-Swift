import UIKit

@objc public protocol GoongAutocompleteDelegate {
    @objc func viewController(_ viewController: GoongAutocompleteViewController, didAutocompleteWith place: Placemark?)
    @objc func viewController(_ viewController: GoongAutocompleteViewController, didFailAutocompleteWithError error: Error?)
}
@objc open class GoongAutocompleteViewController: UIViewController {
    var tableView: UITableView!
    var searchActive : Bool = false
    var searchBar:UISearchBar?
    var searchedPlaces = [Prediction]()
    let decoder = JSONDecoder()
    var geocoder: Geocoder!
    @objc public weak var delegate: GoongAutocompleteDelegate?
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    @objc public convenience init(accessToken: String) {
        self.init()
        self.geocoder = Geocoder(accessToken: accessToken)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        if self.searchBar == nil {
            self.searchBar = UISearchBar()
            self.searchBar!.searchBarStyle = .prominent
            self.searchBar!.tintColor = .black
            self.searchBar!.barTintColor = .white
            self.searchBar!.delegate = self
            self.searchBar!.placeholder = "Search for place";
        }
        self.navigationItem.titleView = searchBar
        setupTableview()
    }
    func setupTableview() {
        self.tableView = UITableView()
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.allowsMultipleSelection = false
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.view.addSubview(tableView)
        self.tableView.frame = self.view.bounds
        self.tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
}
extension GoongAutocompleteViewController: UISearchBarDelegate {
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.cancelSearching()
        searchActive = false;
    }
    
    public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        searchBar.searchTextField.resignFirstResponder()
    }
    
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar!.setShowsCancelButton(true, animated: true)
    }
    
    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.searchBar!.setShowsCancelButton(false, animated: false)
    }
    
    func cancelSearching(){
        searchActive = false;
        self.searchBar!.resignFirstResponder()
        self.searchBar!.text = ""
    }
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.search), object: nil)
        self.perform(#selector(self.search), with: nil, afterDelay: 0.5)
        if(searchBar.text!.isEmpty){
            searchActive = false;
        } else {
            searchActive = true;
        }
    }

    @objc func search() {
        if(searchBar?.text!.isEmpty)!{ } else {
            self.searchPlaces(query: (searchBar?.text)!)
        }
    }
    @objc func searchPlaces(query: String) {
        
        let options = ForwardGeocodeOptions(query: query)
        geocoder.geocode(options) { (result, error) in
            if let err = error {
                print(err.localizedDescription)
            }
            guard let result = result, let predictions = result.predictions, predictions.count > 0 else {
                return
            }
            self.searchedPlaces = predictions
            self.tableView.reloadData()
        }
    }
}
extension GoongAutocompleteViewController: UITableViewDelegate, UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return searchedPlaces.count
    }
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let HeaderCellIdentifier = "Header"
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: HeaderCellIdentifier)
        let place = searchedPlaces[section]
        
        cell.textLabel?.text = place.structuredFormatting?.mainText
        cell.detailTextLabel?.text = place.structuredFormatting?.secondaryText
        
        cell.textLabel?.font = UIFont.systemFont(ofSize: 16)
        cell.textLabel?.textColor = .darkGray
        cell.detailTextLabel?.textColor = .gray
        cell.backgroundColor = .white
        let separator = UIView()
        separator.frame = CGRect(x: 20, y: cell.frame.size.height - 0.5, width: tableView.frame.size.width - 20, height: 0.5)
        separator.backgroundColor = .groupTableViewBackground
        cell.addSubview(separator)
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleSectionTap(gesture:)))

        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        cell.tag = section
        cell.addGestureRecognizer(tap)
        return cell
    }
  
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let place = searchedPlaces[section]
        if place.hasChildren! {
            return place.children!.count
        }
        return 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let child = searchedPlaces[indexPath.section]
        let place = child.children![indexPath.row]
        cell.textLabel?.text = place.content
        cell.detailTextLabel?.text = place.address
        cell.imageView?.image = UIImage(named: "iconLocationPin_gray", in: Bundle(for:self.classForCoder), compatibleWith: nil)
        return cell
    }
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let place = searchedPlaces[indexPath.section].children![indexPath.row]
        self.fetchPlaceID(place.pid!)
    }
    
    func fetchPlaceID(_ placeID: String) {
        geocoder.fetchPlace(from: placeID) { (result, err) in
            if let err = err {
                self.dismiss(animated: true) {
                    self.delegate?.viewController(self, didFailAutocompleteWithError: err)
                }
            }
            guard let result = result else {
                self.dismiss(animated: true) {
                    self.delegate?.viewController(self, didFailAutocompleteWithError: nil)
                }
                return
            }
            self.dismiss(animated: true) {
                self.delegate?.viewController(self, didAutocompleteWith: result.placemark)
            }
            
        }
    }
    @objc func handleSectionTap(gesture: UITapGestureRecognizer) {
        let place = searchedPlaces[gesture.view!.tag]
        self.fetchPlaceID(place.placeID!)
    }
    
    
}
