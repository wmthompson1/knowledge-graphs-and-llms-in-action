KB1932812

## Posted transactions remain with Posting Candidate = Y

Article Information
________________________________________________________________________________________________________________


Description :

Posted transactions remain with Posting Candidate = Y
How to turn off the posting candidate.


Resolution :
If a posted transaction remains with a POSTING_CANDIDATE = Y, there may be future dated transactions to process.  Costing will not turn off the flag until the transaction has been fully journalized.  

To turn the posting candidate off if there are no future dated transactions, prepare the journal in Admin > Costing Tools to force the POSTING_CANDIDATE to N:

Cost to Check:  Select the appropriate type
Enter the Starting and Ending values
Posting Date:  Date journals are currently being prepared for
  ***To verify, check the Inventory or WIP Balance Report.  If journals have been prepared, these reports will include data.
Options:  Un-check 'Exceptions Only' to pull in a specific record
Click the 'Run' icon
Go to Edit > Select All
Go to Edit > Set Posting Candidate
Save
Go to Edit > Select All
Select the 'Journal Preparation' icon


Go to Ledger > Post Manufacturing Journals
Post the appropriate journal type 


Note : POSTING_CANDIDATE field in the PAYABLE and GJ are only used in a Projects database.
 
