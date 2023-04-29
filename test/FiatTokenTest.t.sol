// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import { FiatTokenV3 } from "../src/FiatTokenV3.sol";
import { FiatTokenProxy } from "../src/FiatTokenProxy.sol";

contract FiatTokenTest is Test {

    // Owner and users
    address owner = 0xFcb19e6a322b27c06842A71e8c725399f049AE3a;
    address admin = 0x807a96288A1A408dBC13DE2b1d087d10356395d2;
    address whiteUser = makeAddr("white_user");
    address normalUser = makeAddr("normal_user");
    address USDCAddr = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint256 initialBalance = 100000 ether;
    string mainnet_url = "https://eth-mainnet.g.alchemy.com/v2/-CmqkVjFZ7gnwUdbfGpt_dasLBkBR1ds";
    FiatTokenV3 fiatTokenV3;
    FiatTokenV3 fiatTokenProxy;
    FiatTokenProxy proxy;
    
    function setUp() public {
        // fork mainnet
        uint forkId = vm.createFork(mainnet_url);
        vm.selectFork(forkId);
        proxy = FiatTokenProxy(payable(USDCAddr));
        vm.startPrank(admin);
        fiatTokenV3 = new FiatTokenV3();
        proxy.upgradeTo(address(fiatTokenV3));
        fiatTokenProxy = FiatTokenV3(address(proxy));
        vm.stopPrank();

        vm.startPrank(owner);
        fiatTokenProxy.initializeV3(owner);
        // 白名單
        fiatTokenProxy.whitelist(owner);
        fiatTokenProxy.whitelist(whiteUser);
        // 幫白名單充值
        fiatTokenProxy.mint(whiteUser, initialBalance);
        vm.stopPrank();
    }

    // 白名單可以轉帳成功
    function testWhitelistedUserTransfer() public {
        vm.startPrank(whiteUser);
        bool result = fiatTokenProxy.transfer(normalUser, 1 ether);
        assertEq(result, true);
    }

    // 非白名單會轉帳失敗
    function testNotWhitelistedUserTransfer() public {
        vm.startPrank(normalUser);
        vm.expectRevert(bytes("invalid white list"));
        bool result = fiatTokenProxy.transfer(whiteUser, 1 ether);
        assertEq(result, false);
    }

    // 白名單地址可以 mint token
    function testWhitelistedUserMint() public {
        vm.startPrank(whiteUser);
        bool result = fiatTokenProxy.mint(normalUser, initialBalance);
        assertEq(result, true);
        assertEq(fiatTokenProxy.balanceOf(normalUser), initialBalance);
    }

    // 非白名單地址不可以 mint 不可以 mint 超過限額的 token
    function testNotWhitelistedUserMint() public {
        uint whiteUserInitialBalance = fiatTokenProxy.balanceOf(whiteUser);
        uint minterAllowance = fiatTokenProxy.minterAllowance(normalUser);
        vm.startPrank(normalUser);
        vm.expectRevert(bytes("FiatToken: mint amount exceeds minterAllowance"));
        bool result = fiatTokenProxy.mint(whiteUser, minterAllowance + 1);
        assertEq(result, false);
        assertEq(fiatTokenProxy.balanceOf(whiteUser), whiteUserInitialBalance);
    }
}