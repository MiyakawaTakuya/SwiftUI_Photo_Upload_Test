//
//  ContentView.swift
//  Photo_Upload
//
//  Created by 宮川卓也 on 2021/06/23.
//
import UIKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack{
            SampleViewControllerWrapper()  //SwiftUIでViewControllerを表示する。
        }//VStackここまで
    }
}


// SwiftUIでviewControllerを表示する際に必要なコード
struct SampleViewControllerWrapper : UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> SampleViewController {
        return SampleViewController()
    }
    
    func updateUIViewController(_ uiViewController: SampleViewController, context: Context) {
        
    }
}

/** 従来のViewControllerでviewの作成 */
class SampleViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    //class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    //元々のコード
    private var image: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let btnSelectImage: UIButton = UIButton(frame: CGRect(x: 30, y: 100, width: view.frame.size.width - 60, height: 30))
        btnSelectImage.setTitle("Select image", for: .normal)
        btnSelectImage.setTitleColor(UIColor.systemBlue, for: .normal)
        btnSelectImage.contentHorizontalAlignment = .center
        btnSelectImage.addTarget(self, action: #selector(selectImage), for: .touchUpInside)
        view.addSubview(btnSelectImage)
        
        image = UIImageView(frame: CGRect(x: 30, y: btnSelectImage.frame.origin.y + btnSelectImage.frame.size.height + 30, width: 300, height: 300))
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        view.addSubview(image)
        
        //ボタンのデザイン
        let btnUpload: UIButton = UIButton(frame: CGRect(x: 30, y: image.frame.origin.y + image.frame.size.height + 30, width: view.frame.size.width - 60, height: 40))
        btnUpload.setTitle("Upload to server", for: .normal)
        btnUpload.backgroundColor = UIColor.systemGreen
        btnUpload.setTitleColor(UIColor.white, for: .normal)
        btnUpload.addTarget(self, action: #selector(uploadToServer), for: .touchUpInside)
        btnUpload.layer.cornerRadius = 5
        view.addSubview(btnUpload)
    }
    
    @objc private func uploadToServer(sender: UITapGestureRecognizer) {
        let imageData: Data = image.image!.pngData()!
        let imageStr: String = imageData.base64EncodedString()
        
        let alert = UIAlertController(title: "Loading", message: "Please wait...", preferredStyle: .alert)
        present(alert, animated: true, completion: nil)
        
        let urlString: String = "imageStr=" + imageStr
        
        
        //参考コード
        //「URL(string:~)」構造体を指定して格納することによって後からプログラムでURL情報を使えるようにします
        //構造体はある目的をもったデータやメソッドの集まりです。
        //URL(string:~は文字列からURL情報を分解整理して、URL構造体に格納している
        guard let req_url = URL(string:"http:// localhost/LAB5/Photo_Life/get_file.php")
        else{
            print("エラーでとるよ！")
            return
        }
        var request = URLRequest(url:req_url)
//        var request: URLRequest = URLRequest(url: URL(string:"http:// 192.168.10.112/LAB5/Photo_Life/get_file.php")!)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = urlString.data(using: .utf8)
        
        NSURLConnection.sendAsynchronousRequest(request, queue: .main, completionHandler: { (request, data, error) in
            
            guard let data = data else {
                return
            }
            
            let responseString: String = String(data: data, encoding: .utf8)!
            print("my_log = " + responseString)
            
            alert.dismiss(animated: true, completion: {
                
                let messageAlert = UIAlertController(title: "Success", message: responseString, preferredStyle: .alert)
                messageAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction!) in
                    //
                }))
                
                self.present(messageAlert, animated: true, completion: nil)
            })
        })
    }
    
    @objc private func selectImage(sender: UITapGestureRecognizer) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self as! UIImagePickerControllerDelegate & UINavigationControllerDelegate
        imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
    }
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let chosenImage = info[UIImagePickerController.InfoKey.originalImage.rawValue] as! UIImage
        image.image = chosenImage
        dismiss(animated: true, completion: nil)
    }
    
}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
