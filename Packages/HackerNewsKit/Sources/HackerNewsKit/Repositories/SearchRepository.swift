import Foundation
import Alamofire

public class SearchRepository {
    public static let shared: SearchRepository = .init()
    
    private init() {}
    
    private let baseUrl = "https://hn.algolia.com/api/v1/"
    
    public func search(params: SearchParams, onItemFetched: @escaping (any Item) -> Void) async -> Void {
        guard let urlStr = "\(baseUrl)\(params.filteredQuery)"
                .addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
              let url = URL(string: urlStr) else { return }
        let response = await AF.request(url).serializingString().response
        
        guard let result = try? response.result.get(),
              let map = result.toJSON() as? [String: AnyObject],
              let hits = map["hits"] as? [AnyObject]
        else { return }
        
        for hit in hits {
            guard let hit = hit as? [String: AnyObject],
                  let by = hit["author"] as? String,
                  let createdAt = hit["created_at_i"] as? Int,
                  let idStr = hit["objectID"] as? String,
                  let id = Int(idStr)
            else { continue }
            
            let url = hit["url"] as? String
            let title = hit["title"] as? String
            
            if title?.isEmpty ?? true {
                guard let text = hit["comment_text"] as? String? ?? "",
                      let parentId = hit["parent_id"] as? Int? ?? 0
                else { return }
                let formattedText = text.htmlStripped
                let cmt = Comment(id: id,
                                  parent: parentId,
                                  text: formattedText,
                                  by: by,
                                  time: createdAt)
                onItemFetched(cmt)
            } else {
                let text = hit["story_text"] as? String? ?? ""
                let formattedText = text.htmlStripped
                let score = hit["points"] as? Int
                let descendants = hit["num_comments"] as? Int
                let story = Story(id: id,
                                  parent: nil,
                                  title: title,
                                  text: formattedText,
                                  url: url,
                                  type: "story",
                                  by: by,
                                  score: score,
                                  descendants: descendants,
                                  time: createdAt)
                onItemFetched(story)
            }
        }
    }
}


