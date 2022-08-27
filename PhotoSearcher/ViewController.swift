import UIKit

struct APIResponse: Codable {
    let total: Int
    let total_pages: Int
    let results: [Result]
}

struct Result: Codable {
    let id : String
    let urls: URLS
}

struct URLS: Codable {
    let regular: String
}
class ViewController: UIViewController, UICollectionViewDataSource, UISearchBarDelegate, UICollectionViewDelegate {

    private var collectionView: UICollectionView?
    
    var results: [Result] = []
    
    let searchBar = UISearchBar()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(searchBar)
        searchBar.delegate = self
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: view.frame.size.width/2, height: view.frame.size.height/2)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(CollectionViewCell.self, forCellWithReuseIdentifier: CollectionViewCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
        self.collectionView = collectionView
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        searchBar.frame = CGRect(x: 10, y: view.safeAreaInsets.top, width: view.frame.size.width-20, height: 50)
        collectionView?.frame = CGRect(x: 0, y: Int(view.safeAreaInsets.top)+55, width: Int(view.frame.size.width), height: Int(view.frame.size.height)-55)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        if let text = searchBar.text {
            results = []
            collectionView?.reloadData()
            fetchPhotos(query: text)
        }
    }
    
    func fetchPhotos(query: String) {
        let urlString = "https://api.unsplash.com/search/photos?page=1&per_page=50&query=\(query)&client_id=MnBH0iEppgRrMs0Ttnl5p_PSipnqTavRqCVVsQE0yq8"
        
        guard let url = URL(string: urlString) else {
            return
        }
        let task = URLSession.shared.dataTask(with: url) {[weak self] data, _, error in
            guard let data = data, error == nil else {
                return
            }
            do {
                let jsonResult = try JSONDecoder().decode(APIResponse.self, from: data)
                DispatchQueue.main.async {
                    self?.results = jsonResult.results
                    self?.collectionView?.reloadData()
                }
            } catch {
                print(error)
            }
        }
        task.resume()
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return results.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let imageURLString = results[indexPath.row].urls.regular
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionViewCell.identifier, for: indexPath) as? CollectionViewCell else {return UICollectionViewCell()}
        cell.configure(with: imageURLString)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let config = UIContextMenuConfiguration(identifier: nil,
                                                previewProvider: nil) { _ in
            let save = UIAction(title: "Add to Photos",
                                image: UIImage(systemName: "square.and.arrow.down"),
                                identifier: nil,
                                discoverabilityTitle: nil,
                                state: .off) {[weak self] _ in
                
                let imageURLString = self?.results[indexPath.row].urls.regular
                guard let url = URL(string: imageURLString!) else {
                    return
                }

                URLSession.shared.dataTask(with: url) { data, _, error in
                    guard let data = data, error == nil else {return}
                    DispatchQueue.main.async {
                        let image = UIImage(data: data)
                        let imageData = image?.pngData()
                        let compData = UIImage(data: imageData!)
                        guard let compData = compData else {return}
                        UIImageWriteToSavedPhotosAlbum(compData, nil, nil, nil)
                        }
                }.resume()
                
            }
                
            let share = UIAction(title: "Share...",
                                image: UIImage(systemName: "square.and.arrow.up"),
                                identifier: nil,
                                discoverabilityTitle: nil,
                                state: .off) {[weak self] _ in
                
                let imageURLString = self?.results[indexPath.row].urls.regular
                guard let url = URL(string: imageURLString!) else {
                    return
                }
                
                URLSession.shared.dataTask(with: url) { data, _, error in
                    guard let data = data, error == nil else {return}
                    DispatchQueue.main.async {
                        let image = UIImage(data: data)
                        let shareSheetVC = UIActivityViewController(activityItems: [image!], applicationActivities: nil)
                        self?.present(shareSheetVC,animated: true)
                    }
                }.resume()
                  
               
                  
            }
            
//            let copy = UIAction(title: "Copy",
//                                image: UIImage(systemName: "doc.on.doc"),
//                                identifier: nil,
//                                discoverabilityTitle: nil,
//                                attributes: .disabled,
//                                state: .off) { _ in
//
//
//            }
            
            return UIMenu(title: "",
                          subtitle: nil,
                          image: nil,
                          identifier: nil,
                          options: UIMenu.Options.displayInline,
                          children: [save,share])
        }
        return config
    }
}

