//
//  QuietlyUITests.swift
//  QuietlyUITests
//
//  Created by likai on 2025/12/24.
//

import XCTest

final class QuietlyUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    func testTriggerPermissions() throws {
        // 目的：触发 macOS 的 Automation / Accessibility 权限弹窗
        // 方法：尝试通过 XCUITest 控制 Finder。这通常会触发 "QuietlyUITests-Runner wants to control Finder" 的系统弹窗。
        
        let finder = XCUIApplication(bundleIdentifier: "com.apple.finder")
        // 尝试启动或连接 Finder
        finder.activate()
        
        // 尝试读取 Finder 的窗口列表（这一步通常是权限触发点）
        // 注意：如果权限被拒绝，这里可能会失败或返回空，但我们的目的是“触发弹窗”
        let _ = finder.windows.count
        
        // 简单的断言，确保代码执行到了这里
        XCTAssertTrue(true)
    }
}
