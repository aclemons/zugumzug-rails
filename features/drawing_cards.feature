Feature: Drawing Cards

  Scenario: Drawing a face-up locomotive
    Given it is my turn
    And a locomotive card is face-up
    Then I can draw the face-up locomotive
    And my turn ends

  Scenario: Drawing face-up non-locomotive card
    Given it is my turn
    And a non-locomotive card is face-up
    Then I can draw the non-locomotive card
    And new card is turned over in its place
    And my turn continues

  Scenario: Drawing new destination tickets
    Given it is my turn
    Then I can draw three new destination tickets
    And keep between 1 and 3 of them
