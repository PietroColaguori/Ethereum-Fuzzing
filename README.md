# Project for the course "Security in Software Applications"

In this project I was given a smart contract written in Solidity and I needed to implement different rules, in order to check the validity of the conditions I used the tool [Echidna](https://github.com/crytic/echidna).

The smart contract is named "Taxpayer.sol" and it models a "person", with two smart contracts as parents, that can marry and divorce another smart contract and is enabled to transfer tax allowance, which is based on the age and marital status.

## Interface & Conditions
1. `function marry(Taxpayer spouse_contract) public`: enables the contract to marry another contract in order to do so several conditions must hold: the invoking contract must not be married, the contract passed as argument must not be married, the two contracts must not be underage and the contract passed must have a valid address. After calling the function it is checked that everything went as expected, otherwise the operation is reverted.
2. `function divorce() public`: enables the contract to divorce from the contract previously married with the above function, in order to do so the conditions that must hold are: the contract must be married to a contract with a valid address, the contract divorced must be married with the invoking contract and in the end both contract must not be married anymore, meaning that I set their `spouse` field to `address(0)`.
3. `function transferAllowance(uint change) public`: enables the invoking contract to transfer tax allowance to the spouse, we implement some obvious conditions (e.g. tax allowance transferred must be lower or equal to the tax allowance of the contract) and we also ensure that the sum of the invoking contract's initial tax allowance and the spouse's initial tax allowance is equal to the sum of the invoking contract's final tax allowance and the spouse's final tax allowance (`myInitial + spouseInitial == myFinal + spouseFinal`).


