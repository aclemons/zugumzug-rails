Feature: Building Routes

  Scenario: Building a route
    Given it is my turn
    And I have enough trains
    And the route is not already blocked
    Then I can build a route between two cities
    And I receive points equivelent to the route length

  Scenario: Failing to build a route
    Given it is my turn
    And I do not have enough trains
    And the route is not already blocked
    Then I cannot build a route between two cities
    And I receive no points

  Scenario: Ending the game
    Given it is my turn
    And I have enough trains
    And the route is not already blocked
    And after I have zero to 2 trains left
    Then each player apart from me has one more turn
    And the game then ends
