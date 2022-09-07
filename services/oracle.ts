require("dotenv").config();
const {getUsersInList} = require("./usersApi");
const { ethers } = require("hardhat");
const {oracleContractAbi} = require("./abis");

const oracleAddr = process.env.ORACLE_ADDRESS;
const privateKey = process.env.PRIVATE_KEY;
const provider = new ethers.providers.InfuraProvider("rinkeby", {projectId: process.env.NETWORK_RPC_ID, projectSecret: process.env.NETWORK_RPC_KEY});
// const provider = new ethers.providers.getDefaultProvider('http://127.0.0.1:8545/');

let wallet = new ethers.Wallet(privateKey, provider);
const contract = new ethers.Contract(oracleAddr, oracleContractAbi, provider);

const abiCoder = new ethers.utils.AbiCoder();
const FormatTypes = ethers.utils.FormatTypes;

let response;

exports.oracle = async () =>{ 
contract.on("RequestCredentialsCallback", async (msg_sender, contractAddress, msg_data)=>{
    //get Abi
    let abi = await contract.connect(wallet).abiStorage(contractAddress);
    abi = abi.toString().substring(2);
    let str = '';
    for (var i = 0; i < abi.length; i += 2)
        str += String.fromCharCode(parseInt(abi.substr(i, 2), 16));
    let abiJSON = JSON.parse(str);
    let Interface = new ethers.utils.Interface(abiJSON);
    Interface.format(FormatTypes.minimal);
    let methodId = ethers.utils.hexDataSlice(msg_data, 0, 4);
    let dataType = [];
    let funcName = Interface.getFunction(methodId);

    for(let i = 0; i < funcName.inputs.length; i++){
        console.log(funcName.inputs[i].type);
        dataType.push(funcName.inputs[i].type);
    }
    let params = await abiCoder.decode(dataType, ethers.utils.hexDataSlice(msg_data, 4));

    let forAuthUsers = funcName.name + "_authorized";
    let forUnAuthUsers = funcName.name + "_unauthorized";
    // const callFunction = new ethers.Contract(contractAddress, abiJSON, provider);

    let users = await getUsersInList(params[0]);
    let findUser = users.filter(user => user.list_id === params[1]);

    if(findUser?.length){
        response = 'User is authorized \n  Function Name: '+forAuthUsers+' \n Contract Address: '+contractAddress+'\n List_id: '+ params[0]+'\n Param: '+ params[1] ;
    //   const proof = []; //we'll create proofs later
    //   await callFunction.forAuthUsers(params, proof); // need to use a signer for this
    }else{
        response = 'User is unauthorized \n  Function Name: '+forUnAuthUsers+' \n Contract Address: '+contractAddress+'\n List_id: '+ params[0]+'\n Param: '+ params[1];
        // await callFunction.forUnAuthUsers(params);
    }
    
  }
  );
  return response;
}