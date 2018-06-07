@api
Feature: dav-versions
  Background:
    Given using API version "2"
    And using new DAV path
    And user "user0" has been created
    And file "/davtest.txt" has been deleted for user "user0"

  Scenario: Upload file and no version is available
    When user "user0" uploads file "data/davtest.txt" to "/davtest.txt" using the API
    Then the version folder of file "/davtest.txt" for user "user0" should contain "0" elements

  Scenario: Upload a file twice and versions are available
    When user "user0" uploads file "data/davtest.txt" to "/davtest.txt" using the API
    And user "user0" uploads file "data/davtest.txt" to "/davtest.txt" using the API
    Then the version folder of file "/davtest.txt" for user "user0" should contain "1" element
    And the content length of file "/davtest.txt" with version index "1" for user "user0" in versions folder should be "8"

  Scenario: Remove a file
    Given user "user0" has uploaded file "data/davtest.txt" to "/davtest.txt"
    And user "user0" has uploaded file "data/davtest.txt" to "/davtest.txt"
    And the version folder of file "/davtest.txt" for user "user0" should contain "1" element
    And user "user0" has deleted file "/davtest.txt"
    When user "user0" uploads file "data/davtest.txt" to "/davtest.txt" using the API
    Then the version folder of file "/davtest.txt" for user "user0" should contain "0" elements

  Scenario: Restore a file and check, if the content is now in the current file
    Given user "user0" has uploaded file with content "123" to "/davtest.txt"
    And user "user0" has uploaded file with content "12345" to "/davtest.txt"
    And the version folder of file "/davtest.txt" for user "user0" should contain "1" element
    When user "user0" restores version index "1" of file "/davtest.txt" using the API
    Then the content of file "/davtest.txt" for user "user0" should be "123"

  Scenario: User cannot access meta folder of a file which is owned by somebody else
    Given user "user1" has been created
    And user "user0" has uploaded file with content "123" to "/davtest.txt"
    And we save it into "FILEID"
    When user "user1" sends HTTP method "PROPFIND" to URL "/remote.php/dav/meta/<<FILEID>>"
    Then the HTTP status code should be "404"

  Scenario: User can access meta folder of a file which is owned by somebody else but shared with that user
    Given user "user1" has been created
    And user "user0" has uploaded file with content "123" to "/davtest.txt"
    And user "user0" has uploaded file with content "456789" to "/davtest.txt"
    And we save it into "FILEID"
    When user "user0" creates a share using the API with settings
      | path        | /davtest.txt |
      | shareType   | 0            |
      | shareWith   | user1        |
      | permissions | 8            |
    Then the version folder of fileId "<<FILEID>>" for user "user1" should contain "1" element

	Scenario: sharer of a file see the old version information when the sharee changes the content of the file
		Given user "user0" has been created
		And user "user1" has been created
		And user "user0" has uploaded file with content "user0 content" to "sharefile.txt"
		And user "user0" has shared file "sharefile.txt" with user "user1"
		When user "user1" has uploaded file with content "user1 content" to "/sharefile.txt"
		Then the HTTP status code should be "204"
		And the version folder of file "/sharefile.txt" for user "user0" should contain "1" element

	Scenario: sharer of a file can restore the original content of the file after the file has been modified by the sharee
		Given user "user0" has been created
		And user "user1" has been created
		And user "user0" has uploaded file with content "user0 content" to "sharefile.txt"
		And user "user0" has shared file "sharefile.txt" with user "user1"
		And user "user1" has uploaded file with content "user1 content" to "/sharefile.txt"
		When user "user0" restores version index "1" of file "/sharefile.txt" using the API
		Then the HTTP status code should be "204"
		And the downloaded content when downloading file "/sharefile.txt" for user "user0" with range "bytes=0-12" should be "user0 content"

	Scenario: sharer restores the file inside a shared folder modified by sharee
		Given user "user0" has been created
		And user "user1" has been created
		And user "user0" has created a folder "/sharingfolder"
		And user "user0" has shared folder "/sharingfolder" with user "user1"
		And user "user0" has uploaded file with content "user0 content" to "/sharingfolder/sharefile.txt"
		And user "user1" has uploaded file with content "user1 content" to "/sharingfolder/sharefile.txt"
		When user "user0" restores version index "1" of file "/sharingfolder/sharefile.txt" using the API
		Then the HTTP status code should be "204"
		And the downloaded content when downloading file "/sharingfolder/sharefile.txt" for user "user0" with range "bytes=0-12" should be "user0 content"

	Scenario: sharee restores the file inside a shared folder modified by sharee
		Given user "user0" has been created
		And user "user1" has been created
		And user "user0" has created a folder "/sharingfolder"
		And user "user0" has shared folder "/sharingfolder" with user "user1"
		And user "user0" has uploaded file with content "user0 content" to "/sharingfolder/sharefile.txt"
		And user "user1" has uploaded file with content "user1 content" to "/sharingfolder/sharefile.txt"
		When user "user1" restores version index "1" of file "/sharingfolder/sharefile.txt" using the API
		Then the HTTP status code should be "204"
		And the downloaded content when downloading file "/sharingfolder/sharefile.txt" for user "user1" with range "bytes=0-12" should be "user0 content"

	Scenario: sharer restores the file inside a shared folder created by sharee and modified by sharer
		Given user "user0" has been created
		And user "user1" has been created
		And user "user0" has created a folder "/sharingfolder"
		And user "user0" has shared folder "/sharingfolder" with user "user1"
		And user "user1" has uploaded file with content "user1 content" to "/sharingfolder/sharefile.txt"
		And user "user0" has uploaded file with content "user0 content" to "/sharingfolder/sharefile.txt"
		When user "user0" restores version index "1" of file "/sharingfolder/sharefile.txt" using the API
		Then the HTTP status code should be "204"
		And the downloaded content when downloading file "/sharingfolder/sharefile.txt" for user "user0" with range "bytes=0-12" should be "user1 content"

	Scenario: sharee restores the file inside a shared folder created by sharee and modified by sharer
		Given user "user0" has been created
		And user "user1" has been created
		And user "user0" has created a folder "/sharingfolder"
		And user "user0" has shared folder "/sharingfolder" with user "user1"
		And user "user1" has uploaded file with content "user1 content" to "/sharingfolder/sharefile.txt"
		And user "user0" has uploaded file with content "user0 content" to "/sharingfolder/sharefile.txt"
		When user "user1" restores version index "1" of file "/sharingfolder/sharefile.txt" using the API
		Then the HTTP status code should be "204"
		And the downloaded content when downloading file "/sharingfolder/sharefile.txt" for user "user1" with range "bytes=0-12" should be "user1 content"

	Scenario: sharer restores the file inside a shared folder created by sharee and modified by sharee
		Given user "user0" has been created
		And user "user1" has been created
		And user "user0" has created a folder "/sharingfolder"
		And user "user0" has shared folder "/sharingfolder" with user "user1"
		And user "user1" has uploaded file with content "old content" to "/sharingfolder/sharefile.txt"
		And user "user1" has uploaded file with content "new content" to "/sharingfolder/sharefile.txt"
		When user "user0" restores version index "1" of file "/sharingfolder/sharefile.txt" using the API
		Then the HTTP status code should be "204"
		And the downloaded content when downloading file "/sharingfolder/sharefile.txt" for user "user0" with range "bytes=0-12" should be "old content"

	Scenario: sharee restores the file inside a shared folder created by sharer and modified by sharer
		Given user "user0" has been created
		And user "user1" has been created
		And user "user0" has created a folder "/sharingfolder"
		And user "user0" has shared folder "/sharingfolder" with user "user1"
		And user "user0" has uploaded file with content "old content" to "/sharingfolder/sharefile.txt"
		And user "user0" has uploaded file with content "new content" to "/sharingfolder/sharefile.txt"
		When user "user1" restores version index "1" of file "/sharingfolder/sharefile.txt" using the API
		Then the HTTP status code should be "204"
		And the downloaded content when downloading file "/sharingfolder/sharefile.txt" for user "user1" with range "bytes=0-12" should be "old content"

	Scenario: sharer restores the file inside a group shared folder modified by sharee
		Given user "user0" has been created
		And user "user1" has been created
		And user "user2" has been created
		And group "newgroup" has been created
		And user "user1" has been added to group "newgroup"
		And user "user2" has been added to group "newgroup"
		And user "user0" has created a folder "/sharingfolder"
		And user "user0" has shared folder "/sharingfolder" with group "newgroup"
		And user "user0" has uploaded file with content "user0 content" to "/sharingfolder/sharefile.txt"
		And user "user1" has uploaded file with content "user1 content" to "/sharingfolder/sharefile.txt"
		And user "user2" has uploaded file with content "user2 content" to "/sharingfolder/sharefile.txt"
		When user "user0" restores version index "2" of file "/sharingfolder/sharefile.txt" using the API
		Then the HTTP status code should be "204"
		And the downloaded content when downloading file "/sharingfolder/sharefile.txt" for user "user0" with range "bytes=0-12" should be "user0 content"