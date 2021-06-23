//
//  OkashiData.swift
//  OkashiAPI
//
//  Created by 宮川卓也 on 2021/06/22.
//

import Foundation

//UIKitのUIImageを利用するためにインポートする
//UIImage はアプリ内の画像データを管理するオブジェクト
import UIKit

//identifiableプロトコルを利用してお菓子の情報をまとめる構造体
//identifiableプロトコルに準拠すると一意に識別できる型として定義することができる
//identifiableを指定するとデータを一意に特定するためにidと呼ばれるプロパティを定義する必要がある
struct OkashiItem: Identifiable {
    //UUID(universally unique identifier)を用いてランダムな一意の値を生成
    let id = UUID()
    //その他に　お菓子の名前URL画像を格納できるように定数として宣言する
    //取得したデータは往診しないので定数として宣言する
    //letとvarをしっかりと使い分けられるようにする 予期せぬバグを防ぐことができる
    let name:String
    let link:URL
    let image:UIImage
}

//お菓子データ検索用のクラス
//
class OkashiData: ObservableObject{
    //JSONのデータ構造
    //Codableプロトコルに準拠することで「JSONのデータ項目名」と「プログラムの変数名」を同じ名前にするとJSONを変換したときに一括して変数にデータ格納することができる。
    //レスポンスデータの中の複数アイテムをまとめて扱えるようにstruct構造体として宣言する
    //(オブジェクトとはインスタンス化された変数・構造体・関数メソッドのメモリ内の値のこと)
    struct ResultJson:Codable{
        //JSONのitem内のデータ構造 JSONの中で必要な項目を拾う
        //まず外部データの項目を整理する　そこからどのようにプログラム上格納するか図に整理する
        //Codableは取得したJSONを構造体に格納できるルールを持っているプロトコル
        struct Item:Codable{
            let name:String? //お菓子の名称
            let url:URL? //掲載URL
            let image:URL? //画像URL
        }
        //Item:Codableで拾った情報をまとめて管理する
        //[]で宣言することで複数の構造体を保持できる配列になっている
        //?を付与してnilを許容するオプショナル型として宣言している
        let item:[Item]? //複数要素 letなので再代入は不可
    }
    
    //定義したお菓子データをまとめる構造体を複数保持できるように配列として変数を定義していく
    //お菓子のリスト (Identifiableプロトコル)
    //=[]として複数構造体を保持できるよう配列を作成
    //@Publishedを付与することでプロパティを監視して自動通知をすることができる
    //外部のクラウや構造体からこの[OkashiItem]を参照した時、それらのオブジェクトに更新情報が送られるようになる
    //[OkashiItem]の値が更新されたということが利用する側でわかる
    @Published var okashiList:[OkashiItem] = []
    
    //Web API検索用のメソッド 第一引数：keyword 検索したいわーど
    //keywordが引数でStringがデータ型で文字列型を示している
    func searchOkashi(keyword:String){
        //デバッグエリアに出力
        print(keyword)
        
        //お菓子の検索キーワードをURLエンコードする
        //String型のaddingPercentEncodingメソッドは文字列をエンコードするメソッド
        //引数のwithAllowedCharacters: .urlQueryAllowedでURLパラメータ用のエンコード方法を指定している
        //addingPercentEncodingメソッドでエンコード失敗すると戻り値がnilとなる.
        //nilが保存できるオプショナル変数を安全に参照するためにguard let 文でアンラップしている
        //アンラップに失敗するとelse{}で処理を終了している
        guard let keyword_encode = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)else{
            return
        }
        
        //リクエストURLの組み立て
        //\(keyword_encode)でURLの文字列の中にエンコード済みのキーワードを埋め込んでいる
        //「URL(string:~)」構造体を指定して格納することによって後からプログラムでURL情報を使えるようにします
        //構造体はある目的をもったデータやメソッドの集まりです。
        //URL(string:~は文字列からURL情報を分解整理して、URL構造体に格納している
        guard let req_url = URL(string:"http://www.sysbird.jp/toriko/api/?apikey=guest&format=json&keyword=\(keyword_encode)&max=10&order=r")
        else{
            return
        }
        print(req_url)
        
        //リクエストに必要な情報を生成する リクエスト管理するためのオブジェクトを生成している
        let req = URLRequest(url:req_url)
        //データ転送を管理するためのセッションを生成
        //URLSessionはリクエストURLからデータをダウンロードしたりリクエストURLにデータをアップロードすることができる
        //セッションとはサーバとの通信の開始から終了までを指している
        //第一引数 configuration: .default　デフォルトのセッション構成を指定
        //第二引数 delegate:nil nilにする。ダウンロード後のデータ取り出しをdelegateではなくクロージャで行うため
        //第三引数 メインスレッドに対するキューを取得
        //画面の更新や@Publishedを付与したプロパティを変更する場合はメインスレッドで行う必要がある
        //OperationQueueを用いることで非同期処理を行うことができる
        //非同期処理とは処理の実行中に別の処理を止めないことをいう
        //リクエストが戻ってくる間に他の処理は特段行っていないが、例えば待ち時間にローディング画面にしたりできる
        let session = URLSession(configuration: .default, delegate:nil, delegateQueue:OperationQueue.main)
        
        //リクエストをタスクとして登録
        //第一引数 req リクエストを管理するオブジェクトでダウンロード先や通信方法などが指定されている
        //第二引数 completionHandler クロージャ.
        // ダウンロードが完了するとクロージャであるcompletionHandler: {(data,response,error)...が実行される
        //completionHandler クロージャの第一引数 data 取得後のデータが格納
        //completionHandler クロージャの第二引数 response 通信の状態を示す情報が格納される
        //completionHandler クロージャの第三引数 error 失敗した時のエラー内容
        
        let task = session.dataTask(with:req, completionHandler: {
            (data,response,error) in
            //セッションを終了
            session.finishTasksAndInvalidate()
            //do try catch エラーハンドリング
            do {
                //JSONDecoderのインスタンス取得
                let decoder = JSONDecoder()
                //受け取ったJSONデータをパース ()解析して格納
                //decoder.decodeで取得したJSONデータ(data!)をパースして構造体ResultJsonのデータ構造に合わせて、変数jsonに格納する
                let json = try decoder.decode(ResultJson.self,from:data!)
                //                print(json)
                
                //お菓子データを配列に詰め込む(↑ではデコード後に一括して格納された状態)
                //これから取り出しやすくするために配列して整理して詰め込み直す
                
                //お菓子の情報が取得できているか確認
                //if let文でお菓子データが存在するときにitemsにコピーして次の処理を行う
                if let items = json.item {
                    //お菓子リストの初期化
                    //selfは自分自身を参照するプロパティ class内のクロージャは、参照型のため循環参照が発生する可能性がある
                    //循環参照とは相互の情報を参照し合うループ状態を指す。そのためselfで特定する.
                    self.okashiList.removeAll()
                    //取得しているお菓子の数だけ処理
                    //itemsは配列
                    //for-in文を用いて1要素(1つのお菓子データ)ずつitemに取り出して処理を行う
                    for item in items {
                        //お菓子の名称,掲載URL、画像URLをアンラップ
                        //カンマで繋げて４つの項目に全てに値がある場合に変数に代入して次の処理を行う
                        if let name = item.name ,//値があれば次のカンマ以降のコードを実行
                           let link = item.url ,//値があれば次のカンマ以降のコードを実行
                           let imageUrl = item.image ,//値が無ければ、次の行のデータの処理を移す
                           let imageData = try? Data(contentsOf: imageUrl) ,
                           let image = UIImage(data: imageData)?.withRenderingMode(.alwaysOriginal){
                            //一つのお菓子の構造体をまとめて管理
                            let okashi = OkashiItem(name: name, link: link,image: image)
                            //お菓子の配列へ追加
                            //appendメソッドでデータの追加
                            self.okashiList.append(okashi)
                        }
                    }
                    print(self.okashiList)
                }
                
            } catch { //エラー処理
                print("エラーが出ました")
                
            }
        })  //dataTaskの登録ここまで
        //task.resume() で、.dataTaskメソッドで登録されたリクエストタスクが実行されJSONのダウンロードが始まる
        task.resume()  //ダウンロード開始
    } //func serchiOkashiここまで
}
