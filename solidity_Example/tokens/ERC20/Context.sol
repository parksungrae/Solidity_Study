// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev 가스비 대납 등 metatransaction에서 (msg.sender)와 (msg.sender)가 바뀔 수 있기 때문에 선언
 */
 
abstract contract Context {

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}