@testable
import Ello
import Quick
import Nimble


class PushNotificationControllerSpec: QuickSpec {
    override func spec() {
        describe("PushNotificationController"){
            var currentBadgeCount = 0

            beforeEach {
                currentBadgeCount = UIApplication.sharedApplication().applicationIconBadgeNumber
            }

            afterEach {
                UIApplication.sharedApplication().applicationIconBadgeNumber = currentBadgeCount
            }

            describe("-hasAlert(_:)") {
                context("has alert") {
                    it("returns true") {
                        let userInfo: [NSObject : AnyObject] = [
                            "destination_user_id" : 1234,
                            "application_target" : "notifications/posts/4",
                            "type" : "repost",
                            "aps" : [
                                "alert" : [
                                    "body" : "@bob has reposted one of your posts",
                                    "title" : "New Repost"
                                ],
                                "badge" : NSNumber(integer: 4)
                            ]
                        ]

                        expect(PushNotificationController.sharedController.hasAlert(userInfo)) == true
                    }
                }

                context("no alert") {
                    it("returns false") {
                        let userInfo: [NSObject : AnyObject] = [
                            "destination_user_id" : 1234,
                            "type" : "reset_badge_count",
                            "aps" : [
                                "badge" : NSNumber(integer: 0)
                            ]
                        ]

                        expect(PushNotificationController.sharedController.hasAlert(userInfo)) == false
                    }
                }
            }

            context("-updateBadgeCount(_:)"){

                context("has badge") {
                    it("updates to new value") {
                        UIApplication.sharedApplication().applicationIconBadgeNumber = 5
                        let userInfo: [NSObject : AnyObject] = [
                            "destination_user_id" : 1234,
                            "type" : "reset_badge_count",
                            "aps" : [
                                "badge" : NSNumber(integer: 0)
                            ]
                        ]
                        PushNotificationController.sharedController.updateBadgeCount(userInfo)
                        // yes, apparently, *printing* the value makes this spec pass
                        print("count: \(UIApplication.sharedApplication().applicationIconBadgeNumber)")

                        expect(UIApplication.sharedApplication().applicationIconBadgeNumber) == 0
                    }
                }

                context("no badge") {
                    it("does nothing") {
                        UIApplication.sharedApplication().applicationIconBadgeNumber = 5
                        let userInfo: [NSObject : AnyObject] = [
                            "destination_user_id" : 1234,
                            "type" : "reset_badge_count",
                            "aps" : [
                            ]
                        ]
                        PushNotificationController.sharedController.updateBadgeCount(userInfo)

                        expect(UIApplication.sharedApplication().applicationIconBadgeNumber) == 5
                    }
                }
            }

            describe("requestPushAccessIfNeeded") {
                let keychain = FakeKeychain()

                beforeEach {
                    AuthToken.sharedKeychain = keychain
                }

                context("when the user isn't authenticated") {
                    it("returns .None") {
                        keychain.isPasswordBased = false
                        let controller = PushNotificationController(defaults: NSUserDefaults(), keychain: keychain)
                        let alert = controller.requestPushAccessIfNeeded()
                        expect(alert).to(beNil())
                    }
                }

                context("when the user is authenticated, but has denied access") {
                    it("returns .None") {
                        keychain.isPasswordBased = true

                        let controller = PushNotificationController(defaults: NSUserDefaults(), keychain: keychain)
                        controller.permissionDenied = true
                        let alert = controller.requestPushAccessIfNeeded()

                        expect(alert).to(beNil())
                    }
                }

                context("when the user is authenticated, hasn't previously denied access, and hasn't seen the custom alert before") {
                    it("returns an AlertViewController") {
                        keychain.authToken = "abcde"
                        keychain.isPasswordBased = true

                        let controller = PushNotificationController(defaults: NSUserDefaults(), keychain: keychain)
                        controller.permissionDenied = false
                        controller.needsPermission = true

                        let alert = controller.requestPushAccessIfNeeded()

                        expect(alert).to(beAnInstanceOf(AlertViewController))
                    }
                }
            }
        }

    }
}
