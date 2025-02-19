//
//  OOLoginViewController.swift
//  O2Platform
//
//  Created by 刘振兴 on 2018/4/9.
//  Copyright © 2018年 zoneland. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import CocoaLumberjack
import AVFoundation

/// 登录界面
class OOLoginViewController: OOBaseViewController {

    @IBOutlet weak var logoImageView: UIImageView!
    
    @IBOutlet weak var userNameTextField: OOUITextField!
    
    @IBOutlet weak var passwordTextField: OOUIDownButtonTextField!
    
    @IBOutlet weak var passwordField: OOUITextField!
    
    @IBOutlet weak var copyrightLabel: UILabel!
    
    @IBOutlet weak var submitButton: OOBaseUIButton!
    
    @IBOutlet weak var rebindBtn: UIButton!
    //修改成 其他登录方式按钮
    @IBOutlet weak var bioAuthLoginBtn: UIButton!
    //生物识别登录是否开启
    private var bioIsOpen: Bool = false
    private var bioTypeName: String = ""
    //初始化进入的时候是否直接跳转到生物识别认证登录界面
    private var notJumpBioAuth = false
    //登录方式
    private var loginType = 0 // 0默认的用户名验证码登录 1用户名密码登录
    

    var viewModel:OOLoginViewModel = {
       return OOLoginViewModel()
    }()
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //监听截屏通知
        NotificationCenter.default.addObserver(self, selector: #selector(screenshots),
                                               name: UIApplication.userDidTakeScreenshotNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
                
        //delegate
        passwordTextField.buttonDelegate = self
        setupUI()
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let bioAuthUser = AppConfigSettings.shared.bioAuthUser
        //判断是否当前绑定的服务器的
        if !bioAuthUser.isBlank {
            let array = bioAuthUser.split("^^")
            if array.count == 2 {
                if array[0] == O2AuthSDK.shared.bindUnit()?.id {
                    self.bioIsOpen = true
                }
            }
        }
        if !self.notJumpBioAuth && self.bioIsOpen {
            DDLogDebug("已开启生物识别认证")
            self.gotoBioAuthLogin()
        }
        
    }
     
    
    @IBAction func unwindFromBioAuthLogin(_ unwindSegue: UIStoryboardSegue) {
        if unwindSegue.identifier == "goBack2Login" {
            DDLogDebug("从生物识别认证页面返回的，所以不需要再跳转了。。。。。。")
            notJumpBioAuth = true
        }
    }
    
    @objc private func didEnterBackground() {
        DDLogDebug("进入后台.................")
        self.userNameTextField.text = ""
        self.passwordField.text = ""
    }
    
    //截屏提示
    @objc private func screenshots() {
        self.showSystemAlert(title: L10n.alert, message: L10n.Login.donotScreenshot) { (action) in
            DDLogDebug("确定提示。")
        }
    }
    
    private func setupUI(){
        logoImageView.image = OOCustomImageManager.default.loadImage(.login_avatar)
        let backImageView = UIImageView(image: #imageLiteral(resourceName: "pic_beijing"))
        backImageView.frame = self.view.frame
        //毛玻璃效果
        let blur = UIBlurEffect(style: .light)
        let effectView = UIVisualEffectView(effect: blur)
        effectView.frame = backImageView.frame
        backImageView.addSubview(effectView)
        // 皮肤
        let baseColor = O2ThemeManager.color(for: "Base.base_color")!
        self.passwordTextField.themeUpdate(buttonTitleColor: baseColor)
        self.passwordTextField.themeUpdate(leftImage: O2ThemeManager.image(for: "Icon.icon_verification_code_nor"), leftLightImage: O2ThemeManager.image(for: "Icon.icon_verification_code_sel"), lineColor: baseColor.alpha(0.4), lineLightColor: baseColor)
        self.passwordField.themeUpdate(leftImage: O2ThemeManager.image(for: "Icon.icon_verification_code_nor"), leftLightImage: O2ThemeManager.image(for: "Icon.icon_verification_code_sel"), lineColor: baseColor.alpha(0.4), lineLightColor: baseColor)
        self.userNameTextField.themeUpdate(leftImage: O2ThemeManager.image(for: "Icon.icon_user_nor"), leftLightImage: O2ThemeManager.image(for: "Icon.icon_user_sel"), lineColor: baseColor.alpha(0.4), lineLightColor: baseColor)
        
        self.passwordField.isSecureTextEntry = true
        self.passwordTextField.keyboardType = .numberPad
        self.userNameTextField.returnKeyType = .next
        self.userNameTextField.returnNextDelegate = self
        
        if O2IsConnect2Collect {
            self.rebindBtn.isHidden = false
            self.passwordTextField.isHidden = false //验证码
            self.passwordField.isHidden = true //密码
            self.bioAuthLoginBtn.isHidden = false
        }else {
            self.rebindBtn.isHidden = true
            self.passwordTextField.isHidden = true
            self.passwordField.isHidden = false
            self.bioAuthLoginBtn.isHidden = true
        }
        
//        self.passwordTextField.reactive.isEnabled <~ viewModel.passwordIsValid
//        self.passwordField.reactive.isEnabled <~ viewModel.pwdIsValid
        self.passwordTextField.downButton!.reactive.isEnabled <~ viewModel.passwordIsValid
//        self.submitButton.reactive.isEnabled <~ viewModel.submitButtionIsValid
//        self.submitButton.reactive.backgroundColor <~ viewModel.submitButtonCurrentColor
//        if O2IsConnect2Collect {
//            viewModel.loginControlIsValid(self.userNameTextField, self.passwordTextField, false)
//        }else {
//            viewModel.loginControlIsValid(self.userNameTextField, self.passwordField, true)
//        }
        
        let bioType = O2BioLocalAuth.shared.checkBiometryType()
        switch bioType {
        case O2BiometryType.FaceID:
            self.bioTypeName = L10n.Login.faceRecognitionLogin
            break
        case O2BiometryType.TouchID:
            self.bioTypeName = L10n.Login.fingerprintIdentificationLogin
            break
        default:
            break
        }
        
        
        //版权信息
        self.view.insertSubview(backImageView, belowSubview: self.logoImageView)
        let year = Calendar.current.component(Calendar.Component.year, from: Date())
        copyrightLabel.text = "Copyright © 2015 - \(year)  All Rights Reserved"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func btnReBindNodeAction(_ sender: UIButton) {
        self.showDefaultConfirm(title: L10n.Login.rebind, message: L10n.Login.rebindToNewServiceNode) { (action) in
            O2AuthSDK.shared.clearAllInformationBeforeReBind(callback: { (result, msg) in
                DDLogInfo("清空登录和绑定信息，result:\(result), msg:\(msg ?? "")")
                DBManager.shared.removeAll()
                DispatchQueue.main.async {
                    self.forwardDestVC("login", nil)
                }
            })
        }
        
    }
    
    @IBAction func bioAuthLoginBtnAction(_ sender: UIButton) {
        //弹出选择登录方式
        var loginActions: [UIAlertAction] = []
        if self.loginType == 0 { //当前是验证码登录
            let passwordLogin = UIAlertAction(title: L10n.Login.passwordLogin, style: .default) { (action) in
                self.change2PasswordLogin()
            }
            loginActions.append(passwordLogin)
        }else {
            let phoneCodeLogin = UIAlertAction(title: L10n.Login.verificationCodeLogin, style: .default) { (action) in
                self.change2PhoneCodeLogin()
            }
            loginActions.append(phoneCodeLogin)
        }
        if self.bioIsOpen {
            let bioLogin = UIAlertAction(title: self.bioTypeName, style: .default) { (action) in
                self.gotoBioAuthLogin()
            }
            loginActions.append(bioLogin)
        }
        self.showSheetAction(title: L10n.alert, message: L10n.Login.selectFollowLoginMethod, actions: loginActions)
//        self.gotoBioAuthLogin()
    }
    
    private func change2PasswordLogin() {
        self.passwordTextField.isHidden = true //验证码
        self.passwordField.isHidden = false //密码
        self.loginType = 1
    }
    
    private func change2PhoneCodeLogin() {
        self.passwordTextField.isHidden = false //验证码
        self.passwordField.isHidden = true //密码
        self.loginType = 0
    }
    
    @IBAction func btnLogin(_ sender: OOBaseUIButton) {
        self.view.endEditing(true)
        let credential = userNameTextField.text ?? ""
        var codeAnswer = ""
        if O2IsConnect2Collect {
            if self.loginType == 0 {
                codeAnswer = passwordTextField.text ?? ""
            }else {
                codeAnswer = passwordField.text ?? ""
            }
        }else {
            codeAnswer = passwordField.text ?? ""
        }
        
        if credential == "" || codeAnswer == "" {
            self.showError(title: L10n.Login.mobilePhoneNumberPasswordIsEmptry)
            return
        }
        self.showLoading()
        if O2IsConnect2Collect {
            if self.loginType == 0 {
                passwordTextField.stopTimerButton()
                
                //app 上架用 sample服务器 固定的手机号码和验证码
                if credential == "13912345678" && codeAnswer == "5678" && O2UserDefaults.shared.unit?.centerHost == "sample.o2oa.net" {
                    DDLogDebug("sample 测试用的。。。。。。。。")
                    O2AuthSDK.shared.loginWithPassword(username: credential, password: "o2") { (result, msg) in
                        if result {
                            self.hideLoading()
                            self.gotoMain()
                        }else  {
                            self.showError(title: L10n.Login.loginErrorWith(msg ?? ""))
                        }
                    }
                } else {
                    O2AuthSDK.shared.login(mobile: credential, code: codeAnswer) { (result, msg) in
                        if result {
                            self.hideLoading()
                            self.gotoMain()
                        }else  {
                            self.showError(title: L10n.Login.loginErrorWith(msg ?? ""))
                        }
                    }
                }
            }else {
                O2AuthSDK.shared.loginWithPassword(username: credential, password: codeAnswer) { (result, msg) in
                    if result {
                        self.hideLoading()
                        self.gotoMain()
                    }else  {
                        self.showError(title: L10n.Login.loginErrorWith(msg ?? ""))
                    }
                }
            }
        }else {
            //todo内网版本登录
            O2AuthSDK.shared.loginWithPassword(username: credential, password: codeAnswer) { (result, msg) in
                if result {
                    self.hideLoading()
                    self.gotoMain()
                }else  {
                    self.showError(title: L10n.Login.loginErrorWith(msg ?? ""))
                }
            }
        }
        
    }
    
    private func gotoMain() {
        //跳转到主页
        let destVC = O2MainController.genernateVC()
//        destVC.selectedIndex = 2 // 首页选中 TODO 图标不亮。。。。。
        UIApplication.shared.keyWindow?.rootViewController = destVC
        UIApplication.shared.keyWindow?.makeKeyAndVisible()
    }

    private func gotoBioAuthLogin() {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "showBioAuthLogin", sender: nil)
        }
    }
}

extension OOLoginViewController:OOUIDownButtonTextFieldDelegate {
    func viewButtonClicked(_ textField: OOUIDownButtonTextField, _ sender: OOTimerButton) {
        guard let credential = userNameTextField.text else {
            self.showError(title: L10n.Login.pleaseEnterMobilePhone)
            sender.stopTiming()
            return
        }
        O2AuthSDK.shared.sendLoginSMS(mobile: credential) { (result, msg) in
            if !result {
                DDLogError((msg ?? ""))
                self.showError(title: L10n.Login.sendCodeFail)
            }
        }
        
    }
}

extension OOLoginViewController: OOUITextFieldReturnNextDelegate {
    func next() {
        if self.userNameTextField.isFirstResponder {
            if self.passwordField.isHidden == false {
                self.passwordField.becomeFirstResponder()
            }
            if self.passwordTextField.isHidden == false {
                self.passwordTextField.becomeFirstResponder()
            }
        }
    }
    
    
}

