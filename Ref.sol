// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SpinApeRef is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    IERC20 public usdtToken;

    mapping(address => address) listRef;
    mapping(address => bool) listLeader;
    mapping(address => uint256) totalUsdOfUser;
    uint256 totalUsdNeed;

    event CreateRef(address user, address refBy);

    function getRef(address _user) external view returns (address) {
        return listRef[_user];
    }

    function calculateFundRef(
        address sender,
        uint256 amount,
        address refBy
    ) public returns (uint256) {
        uint256 totalUsdNeedPerTransaction = 0;
        address rfL1 = listRef[sender];
        if (refBy != address(0) && rfL1 == address(0)) {
            require(sender != refBy, "Can't introduce myself");
            listRef[sender] = refBy;
            rfL1 = refBy;
            emit CreateRef(sender, refBy);
        }
        address rfL2 = listRef[rfL1];
        address rfL3 = listRef[rfL2];

        if (
            listLeader[rfL1] == true ||
            listLeader[rfL2] == true ||
            listLeader[rfL3] == true
        ) {
            if (rfL1 != address(0)) {
                totalUsdOfUser[rfL1] += this.calculatePercent(amount, 500);
                totalUsdNeed += this.calculatePercent(amount, 500);
                totalUsdNeedPerTransaction += this.calculatePercent(
                    amount,
                    500
                );
            }
            if (rfL2 != address(0)) {
                totalUsdOfUser[rfL2] += this.calculatePercent(amount, 300);
                totalUsdNeed += this.calculatePercent(amount, 300);
                totalUsdNeedPerTransaction += this.calculatePercent(
                    amount,
                    300
                );
            }
            if (rfL3 != address(0)) {
                totalUsdOfUser[rfL3] += this.calculatePercent(amount, 200);
                totalUsdNeed += this.calculatePercent(amount, 200);
                totalUsdNeedPerTransaction += this.calculatePercent(
                    amount,
                    200
                );
            }
        } else {
            if (rfL1 != address(0)) {
                totalUsdOfUser[rfL1] += this.calculatePercent(amount, 300);
                totalUsdNeed += this.calculatePercent(amount, 300);
                totalUsdNeedPerTransaction += this.calculatePercent(
                    amount,
                    300
                );
            }
            if (rfL2 != address(0)) {
                totalUsdOfUser[rfL2] += this.calculatePercent(amount, 200);
                totalUsdNeed += this.calculatePercent(amount, 200);
                totalUsdNeedPerTransaction += this.calculatePercent(
                    amount,
                    200
                );
            }
        }
        return totalUsdNeedPerTransaction;
    }

    function calculatePercent(uint256 total, uint256 percent)
        public
        pure
        returns (uint256)
    {
        return (total / 10000) * percent;
    }

    function setUsd(address usdAddress) public onlyOwner {
        usdtToken = IERC20(usdAddress);
        // Approve
        usdtToken.approve(
            address(this),
            115792089237316195423570985008687907853269984665640564039457584007913129639935
        );
    }

    function setLeader(address[] memory listAddres) public onlyOwner {
        for (uint256 index = 0; index < listAddres.length; index++) {
            listLeader[listAddres[index]] = true;
        }
    }

    function getTotalUsd(address userAddress) public view returns (uint256) {
        return totalUsdOfUser[userAddress];
    }

    function claimUsd(uint256 amount) public {
        require(amount <= totalUsdOfUser[msg.sender], "Error: Invalid amount");
        totalUsdOfUser[msg.sender] -= amount;
        usdtToken.transfer(msg.sender, amount);
    }
}
