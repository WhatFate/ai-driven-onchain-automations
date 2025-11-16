// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract MockAggregator {
  int256 public s_answer;
  bool public newRoundCalled;

  function setLatestAnswer(int256 answer) public {
    s_answer = answer;
  }

  function latestAnswer() public view returns (int256) {
    return s_answer;
  }

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) 
  {
    return (18446744073709579662, s_answer, 1763196324, 1763196324, 18446744073709579662);
  }

  function requestNewRound() external returns (uint80) {
    newRoundCalled = true;
    return 1;
  }
}
