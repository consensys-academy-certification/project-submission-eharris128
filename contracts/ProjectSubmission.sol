pragma solidity ^0.5.0;

contract ProjectSubmission {

    address payable public owner;
    uint256 public ownerBalance;

    constructor() public {
      owner = msg.sender;
    }

    modifier onlyOwner() {
      require(msg.sender == owner, "Must be the owner to use this function");
      _;
    }

    struct University {
      bool available;
      uint256 balance;
      address payable accountAddress;
    }

    mapping (address => University) public universities;

    enum ProjectStatus {
      Waiting,
      Rejected,
      Approved,
      Disabled
    }

    struct Project {
        address payable author;
        address university;
        ProjectStatus status;
        uint256 balance;
    }

    mapping (bytes32 => Project) public projects;

    function registerUniversity(address payable universityAddress) public onlyOwner() {
      universities[universityAddress] = University(true, 0, universityAddress);
    }

    function disableUniversity(address universityAddress) public onlyOwner() {
      require(universities[universityAddress].accountAddress == universityAddress, "This university is not registered.");
      universities[universityAddress].available = false;
    }

    function submitProject(bytes32 projectHash, address payable universityAddress) public payable {
      require(msg.value >= 1 ether, "Must pay 1 ether fee to submit a project");
      require(universities[universityAddress].available, "This university is not accepting project submissions");

      projects[projectHash] = Project(msg.sender, universityAddress, ProjectStatus.Waiting, 0);
      ownerBalance += msg.value;
    }

    function disableProject(bytes32 projectHash) public onlyOwner() {
      projects[projectHash].status = ProjectStatus.Disabled;
    }

    function reviewProject(bytes32 projectHash, uint8 projectStatus) public onlyOwner() {
      require(projects[projectHash].status == ProjectStatus.Waiting, "Cannot review projects that do not have a status of 'Waiting'");
      projects[projectHash].status = ProjectStatus(projectStatus);
    }

    function donate(bytes32 projectHash) public payable {
      Project storage project = projects[projectHash];
      require(project.status == ProjectStatus.Approved, "Only approved projects can receive donations");

      uint256 projectDonation = msg.value * 7 / 10; // 70% of msg value
      uint256 universityDonation = msg.value * 1 / 5; // 20% of msg value
      uint256 ownerDonation = msg.value / 10; // 10% of msg value

      project.balance += projectDonation;
      universities[project.university].balance += universityDonation;
      ownerBalance += ownerDonation;
    }

    // handles owner and university withdrawls
    function withdraw() public payable {
      if (msg.sender == owner) {
        uint256 ownerBalanceSnapshot = ownerBalance;
        ownerBalance = 0;
        owner.transfer(ownerBalanceSnapshot);
      }

      if (msg.sender == universities[msg.sender].accountAddress) {
        University memory university = universities[msg.sender];
        uint256 universityBalanceSnapshot = university.balance;
        university.balance = 0;
        msg.sender.transfer(universityBalanceSnapshot);
      }
    }

    // handles student(author) withdrawls
    function withdraw(bytes32 projectHash) public payable {
      Project memory project = projects[projectHash];
      require(msg.sender == project.author, "Cannot withdraw from project unless you are the author!");
      uint256 projectBalanceSnapshot = project.balance;
      project.balance = 0;
      msg.sender.transfer(projectBalanceSnapshot);
    }
}