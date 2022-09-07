// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./CredentialEvent.sol";

contract Gateable {


    address private CREDENTIAL_ORACLE;
    CredentialEvent public CREDENTIAL_EVENT;

constructor(CredentialEvent _credentialOracle) {
    CREDENTIAL_ORACLE = address(_credentialOracle);
    CREDENTIAL_EVENT = _credentialOracle;
}

function has_credential(address _contractAddr) public {
	CREDENTIAL_EVENT.emitEvent(msg.sender, _contractAddr, msg.data);
}

function credentialCallback() public view {
  require(msg.sender == CREDENTIAL_ORACLE, "Credential CallBack: Only the oracle can call this function");
}
}
