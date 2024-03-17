// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract Taxpayer {

 uint age; 

 bool isMarried;

 /* Reference to spouse if person is married, address(0) otherwise */
 address spouse; 
 address parent1;
 address parent2; 

 /* Constant default income tax allowance */
 uint constant  DEFAULT_ALLOWANCE = 5000;

 /* Constant income tax allowance for Older Taxpayers over 65 */
 uint constant ALLOWANCE_OAP = 7000;

 /* Income tax allowance */
 uint tax_allowance; 

 uint income;

 constructor(address p1, address p2) {
   age = 0;
   isMarried = false;
   parent1 = p1;
   parent2 = p2;
   spouse = address(0);
   income = 0;
   tax_allowance = DEFAULT_ALLOWANCE;
 } 


 //We require new_spouse != address(0);
 function marry(Taxpayer spouse_contract) public {
   require(this.getAge() >= 18, "You are a minor");
   require(!spouse_contract.isMinor(), "You cannot marry a minor");
   require(address(spouse_contract) != address(0), "Invalid spouse address [0x0]");
   require(isMarried == false , "You are already married, divorce first [1]");
   require(this.getSpouse() == address(0), "You are already married, divorse first [2]");
   require(!spouse_contract.getIsMarried(), "New spouse is already married");
   spouse = address(spouse_contract);
   spouse_contract.setSpouse(address(this));
   require(spouse_contract.getSpouse() == address(this), "You married someone else's spouse");
   isMarried = true;
   require(spouse_contract.getIsMarried(), "You married someone who didn't marry you");
 }
 
 function divorce() public {
   require(isMarried, "You are not married, no one to divorce");
   Taxpayer sp = Taxpayer(address(spouse));
   require(sp.getSpouse() == address(this), "You are divorcing someone that is not married to you");
   sp.setSpouse(address(0));
   require(sp.getSpouse() == address(0), "Something went wrong, spouse did not divorce you");
   spouse = address(0);
   require(this.getSpouse() == address(0), "Something went wrong, you did not divorce correctly");
   isMarried = false;
   require(!this.getIsMarried(), "Your status did not update correctly");
   require(!sp.getIsMarried(), "Your spouse did not update the status");
 }

 /* Transfer part of tax allowance to own spouse */
 function transferAllowance(uint change) public {
   uint myInitial = this.getTaxAllowance();
   require(this.getAge() >= 18);
   require(isMarried, "You are not married, cannot transfer");
   require(spouse != address(0), "You are married to 0x0");
   require(change <= tax_allowance, "You don't have enough tax allowance");
   tax_allowance = tax_allowance - change;
   Taxpayer sp = Taxpayer(address(spouse));
   uint spouseInitial = sp.getTaxAllowance();
   sp.setTaxAllowance(sp.getTaxAllowance()+change);
   require(this.getTaxAllowance() == myInitial - change, "Something went wrong for your tax allowance");
   require(sp.getTaxAllowance() == spouseInitial + change, "Something went wrong for spouse tax allowance");
   require(myInitial + spouseInitial == this.getTaxAllowance() + sp.getTaxAllowance(), "Tax allowances are not the same");
 }

 function haveBirthday() public {
   age++;
   if(age >= 65) {
     this.setTaxAllowance(ALLOWANCE_OAP);
   }
 }

function setSpouse(address sp) public {
    spouse = sp;
}
function getSpouse() public view returns (address) {
    return spouse;
}
function setTaxAllowance(uint ta) public {
    tax_allowance = ta;
}
function getTaxAllowance() public view returns (uint) {
    return tax_allowance;
}
function getIsMarried() public view returns (bool) {
    return isMarried;
}
function getAge() public view returns (uint) {
    return age;
}
function setAge(uint a) public {
    age = a;
    if(a >= 65) {
        this.setTaxAllowance(ALLOWANCE_OAP);
    }
}
function isMinor() public view returns (bool) {
    return age <= 17;
}
function setIsMarried(bool x) public {
    isMarried = x;
}
}


/*  ===============
 *  ECHIDNA TESTING
 *  ===============
 */

contract TaxpayerTest is Taxpayer {

    event LogValue(string message, uint value);
    event LogBool(string message, bool value);
    event AssertionFailed(uint value);

    constructor() Taxpayer(address(0x1), address(0x2)) {}

    // TESTED FUNCTION: marry =====================================

    // Fuzz testing with the contract and data fields
    function assert_fuzzMarry(Taxpayer new_spouse, uint myAge, uint spouseAge, address myOldSpouse, address spouseSpouse) public {
        this.setAge(myAge);
        this.setSpouse(myOldSpouse);
        if(myOldSpouse == address(0)) { this.setIsMarried(false); }
        else { this.setIsMarried(true); }
        new_spouse.setAge(spouseAge);
        new_spouse.setSpouse(spouseSpouse);
        if(spouseSpouse == address(0)) { new_spouse.setIsMarried(false); }
        else { new_spouse.setIsMarried(true); }

        if(address(new_spouse) != address(0)) {
            bool preMarried = this.getIsMarried();
            address preSpouse = this.getSpouse();
            bool preSpouseMarried = new_spouse.getIsMarried();
            address preSpouseSpouse = new_spouse.getSpouse();

            this.marry(new_spouse);

            bool postMarried = this.getIsMarried();
            address postSpouse = this.getSpouse();
            bool postSpouseMarried = new_spouse.getIsMarried();
            address postSpouseSpouse = new_spouse.getSpouse();

            assert(address(new_spouse) != address(0));
            assert(this.getAge() >= 18);
            assert(new_spouse.getAge() >= 18);
            assert(!preMarried);
            assert(preSpouse == address(0));
            assert(postMarried);
            assert(address(postSpouse) == address(new_spouse));
            assert(!preSpouseMarried);
            assert(preSpouseSpouse == address(0));
            assert(postSpouseSpouse == address(this));
            assert(postSpouseMarried);
        }
        emit LogValue("My age", myAge);
        emit LogValue("Age of spouse", spouseAge);
        emit AssertionFailed(spouseAge);
    }

    // TESTED FUNCTION: divorce =====================================
    
    // REMINDER screen of success
    // Fuzzing on divorce function -> since marry has no args, I fuzz on marry args
    function assert_fuzzDivorce(Taxpayer currentSpouse) public {
        this.setSpouse(address(currentSpouse));
        bool preMarried = this.getIsMarried();
        address preSpouse = this.getSpouse();

        this.divorce();

        bool postMarried = this.getIsMarried();
        address postSpouse = this.getSpouse();

        assert(preMarried);
        assert(preSpouse == address(currentSpouse));
        assert(!postMarried);
        assert(postSpouse == address(0));
    }

    // TESTED FUNCTION: transferAllowance =====================================
    function assert_fuzzTransferTaxAllowance(Taxpayer currentSpouse, uint change, uint spouseAge, uint myAge) public {
        this.setAge(myAge);
        currentSpouse.setAge(spouseAge);
        if(spouseAge >= 65) { currentSpouse.setTaxAllowance(ALLOWANCE_OAP); }
        else { currentSpouse.setTaxAllowance(DEFAULT_ALLOWANCE); }
        this.marry(currentSpouse);

        // check if necessary
        bool bothOver65 = (this.getAge() >= 65 && currentSpouse.getAge() >= 65);
        bool oneOver65 = ((this.getAge() >= 65 && currentSpouse.getAge() < 65) || 
                          (currentSpouse.getAge() >= 65 && this.getAge() < 65));
        bool noneOver65 = (this.getAge() < 65 && currentSpouse.getAge() < 65);

        uint myInitial = this.getTaxAllowance();
        uint spouseInitial = currentSpouse.getTaxAllowance();
        this.transferAllowance(change);
        uint myFinal = this.getTaxAllowance();
        uint spouseFinal = currentSpouse.getTaxAllowance();
        
        assert(change <= this.getTaxAllowance());
        assert(myInitial + spouseInitial == myFinal + spouseFinal);
    }
    
}
