// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./NonblockingLzAppUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "../IOFT20Core.sol";
import "./IERC165Upgradeable.sol";

abstract contract OFT20CoreUpgradeable is
    NonblockingLzAppUpgradeable,
    ERC165Upgradeable,
    IOFT20Core
{
    uint256 public constant NO_EXTRA_GAS = 0;
    uint256 public constant FUNCTION_TYPE_SEND = 1;
    bool public useCustomAdapterParams;

    function __OFT20CoreUpgradeable_init(address _lzEndpoint)
        internal
        onlyInitializing
    {
        __NonBlockingLzApp_init(_lzEndpoint);
        __ERC165_init();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IOFT20Core).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function estimateSendFee(
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256 _amount,
        bool _useZro,
        bytes memory _adapterParams
    ) public view virtual override returns (uint256 nativeFee, uint256 zroFee) {
        // mock the payload for send()
        bytes memory payload = abi.encode(_toAddress, _amount);
        return
            lzEndpoint.estimateFees(
                _dstChainId,
                address(this),
                payload,
                _useZro,
                _adapterParams
            );
    }

    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256 _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) public payable virtual override {
        _send(
            _from,
            _dstChainId,
            _toAddress,
            _amount,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );
    }

    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64, /*_nonce*/
        bytes memory _payload
    ) internal virtual override {
        // decode and load the toAddress
        (bytes memory toAddressBytes, uint256 amount) = abi.decode(
            _payload,
            (bytes, uint256)
        );
        address toAddress;
        assembly {
            toAddress := mload(add(toAddressBytes, 20))
        }

        _creditTo(_srcChainId, toAddress, amount);

        emit ReceiveFromChain(_srcChainId, _srcAddress, toAddress, amount);
    }

    function _send(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256 _amount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal virtual {
        _debitFrom(_from, _dstChainId, _toAddress, _amount);

        bytes memory payload = abi.encode(_toAddress, _amount);
        if (useCustomAdapterParams) {
            _checkGasLimit(
                _dstChainId,
                FUNCTION_TYPE_SEND,
                _adapterParams,
                NO_EXTRA_GAS
            );
        } else {
            require(
                _adapterParams.length == 0,
                "LzApp: _adapterParams must be empty."
            );
        }
        _lzSend(
            _dstChainId,
            payload,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParams
        );

        emit SendToChain(_dstChainId, _from, _toAddress, _amount);
    }

    function setUseCustomAdapterParams(bool _useCustomAdapterParams)
        external
        onlyOwner
    {
        useCustomAdapterParams = _useCustomAdapterParams;
    }

    function _debitFrom(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256 _amount
    ) internal virtual;

    function _creditTo(
        uint16 _srcChainId,
        address _toAddress,
        uint256 _amount
    ) internal virtual;
}
