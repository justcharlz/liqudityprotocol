// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract CredentialEvent {
  mapping(address => bytes) public abiStorage;
  
 event RequestCredentialsCallback(address original_msg_sender, address contractAddr, bytes original_msg_data);

function emitEvent(address _sender, address _contractAddr, bytes calldata _data) public {
    emit RequestCredentialsCallback(_sender, _contractAddr, _data);
  }

function storeAbi(address _contractAddr, bytes calldata _abiData) public {

  abiStorage[_contractAddr] = _abiData;
}

}