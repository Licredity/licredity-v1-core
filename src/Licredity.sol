// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.30;

import {IERC721TokenReceiver} from "@forge-std/interfaces/IERC721.sol";
import {ILicredity} from "./interfaces/ILicredity.sol";
import {Math} from "./libraries/Math.sol";
import {Fungible} from "./types/Fungible.sol";
import {NonFungible} from "./types/NonFungible.sol";
import {Position} from "./types/Position.sol";
import {BaseHooks} from "./BaseHooks.sol";
import {DebtToken} from "./DebtToken.sol";

/// @title Licredity
/// @notice Implementation of the ILicredity interface
contract Licredity is ILicredity, IERC721TokenReceiver, BaseHooks, DebtToken {
    using Math for uint256;

    Fungible transient stagedFungible;
    uint256 transient stagedFungibleBalance;
    NonFungible transient stagedNonFungible;

    uint256 internal totalDebtShare = 1e6; // can never be redeemed, prevents inflation attack and behaves like bad debt
    uint256 internal totalDebtAmount = 1; // establishes the initial conversion rate and inflation attack difficulty
    uint256 internal positionCount;
    mapping(uint256 => Position) internal positions;

    constructor(address poolManager, string memory name, string memory symbol, uint8 decimals)
        BaseHooks(poolManager)
        DebtToken(name, symbol, decimals)
    {}

    /// @inheritdoc ILicredity
    function unlock(bytes calldata data) external returns (bytes memory result) {
        // TODO: require locked
        // TODO: unlock

        // TODO: invoke unlock callback and assign result

        // TODO: ensure every modified position is healthy
        // TODO: lock
    }

    /// @inheritdoc ILicredity
    function open() external returns (uint256 positionId) {
        positionId = ++positionCount;
        positions[positionId].setOwner(msg.sender);

        emit OpenPosition(positionId, msg.sender);
    }

    /// @inheritdoc ILicredity
    function close(uint256 positionId) external {
        Position storage position = positions[positionId];
        require(position.owner == msg.sender, NotPositionOwner());
        require(position.isEmpty(), PositionNotEmpty());

        delete positions[positionId];

        emit ClosePosition(positionId);
    }

    /// @inheritdoc ILicredity
    function stageFungible(Fungible fungible) external {
        stagedFungible = fungible;
        if (!fungible.isNative()) {
            stagedFungibleBalance = fungible.balanceOf(address(this));
        }
    }

    /// @inheritdoc ILicredity
    function exchangeFungible(address recipient) external {
        // TODO: implement
    }

    /// @inheritdoc ILicredity
    function depositFungible(uint256 positionId) external payable {
        Position storage position = positions[positionId];
        require(position.owner != address(0), PositionDoesNotExist());
        Fungible fungible = stagedFungible;

        uint256 amount;
        if (fungible.isNative()) {
            amount = msg.value;
        } else {
            require(msg.value == 0, NonZeroNativeValue());
            amount = fungible.balanceOf(address(this)) - stagedFungibleBalance;
        }

        stagedFungible = Fungible.wrap(address(0));
        position.addFungible(fungible, amount);

        emit DepositFungible(positionId, fungible, amount);
    }

    /// @inheritdoc ILicredity
    function withdrawFungible(uint256 positionId, Fungible fungible, uint256 amount, address recipient) external {
        Position storage position = positions[positionId];
        require(position.owner == msg.sender, NotPositionOwner());

        // TODO: add position to health check list
        position.removeFungible(fungible, amount);
        fungible.transfer(amount, recipient);

        emit WithdrawFungible(positionId, fungible, recipient, amount);
    }

    /// @inheritdoc ILicredity
    function stageNonFungible(NonFungible nonFungible) external {
        require(nonFungible.owner() != address(this), NonFungibleAlreadyOwned());

        stagedNonFungible = nonFungible;
    }

    /// @inheritdoc ILicredity
    function depositNonFungible(uint256 positionId) external {
        Position storage position = positions[positionId];
        require(position.owner != address(0), PositionDoesNotExist());
        NonFungible nonFungible = stagedNonFungible;
        require(nonFungible.owner() == address(this), NonFungibleNotOwned());

        stagedNonFungible = NonFungible.wrap(bytes32(0));
        position.addNonFungible(nonFungible);

        emit DepositNonFungible(positionId, nonFungible);
    }

    /// @inheritdoc ILicredity
    function withdrawNonFungible(uint256 positionId, NonFungible nonFungible, address recipient) external {
        Position storage position = positions[positionId];
        require(position.owner == msg.sender, NotPositionOwner());

        // TODO: add position to health check list
        require(position.removeNonFungible(nonFungible), NonFungibleNotInPosition());
        nonFungible.transfer(recipient);

        emit WithdrawNonFungible(positionId, nonFungible, recipient);
    }

    /// @inheritdoc ILicredity
    function addDebt(uint256 positionId, uint256 share, address recipient) external returns (uint256 amount) {
        Position storage position = positions[positionId];
        require(position.owner == msg.sender, NotPositionOwner());

        // TODO: add position to health check list
        // TODO: disburse interest, which also updates totalDebtAmount
        amount = share.fullMulDiv(totalDebtAmount, totalDebtShare);
        _mint(recipient, amount);

        totalDebtShare += share;
        totalDebtAmount += amount;
        position.addDebtShare(share);
        if (recipient == address(this)) {
            position.addFungible(Fungible.wrap(address(this)), amount);

            emit DepositFungible(positionId, Fungible.wrap(address(this)), amount);
        }

        emit AddDebt(positionId, recipient, share, amount);
    }

    /// @inheritdoc ILicredity
    function removeDebt(uint256 positionId, uint256 share, bool useBalance) external returns (uint256 amount) {
        Position storage position = positions[positionId];

        // TODO: disburse interest, which also updates totalDebtAmount
        amount = share.fullMulDivUp(totalDebtAmount, totalDebtShare);
        if (useBalance) {
            require(position.owner == msg.sender, NotPositionOwner());
            position.removeFungible(Fungible.wrap(address(this)), amount);
            _burn(address(this), amount);

            emit WithdrawFungible(positionId, Fungible.wrap(address(this)), address(0), amount);
        } else {
            require(position.owner != address(0), PositionDoesNotExist());
            _burn(msg.sender, amount);
        }

        totalDebtShare -= share;
        totalDebtAmount -= amount;
        position.removeDebtShare(share);

        emit RemoveDebt(positionId, share, amount, useBalance);
    }

    /// @inheritdoc ILicredity
    function seize(uint256 positionId, address recipient) external returns (uint256 deficit) {
        // TODO: implement
    }

    /// @inheritdoc IERC721TokenReceiver
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
