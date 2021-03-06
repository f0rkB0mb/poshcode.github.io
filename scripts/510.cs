using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Net.Mail;

public partial class MailboxTaskResults : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        Response.Write("Here are the results of the  Domain mailbox task request...<br /><br />");
        runposh("Add-PSSnapin Microsoft.Exchange.Management.PowerShell.Admin");

// Variable Definition
        string strAdminID = Session["AdminID"].ToString();
        string strUserDN = Session["DirPath"].ToString();
        string strOldAddress = Session["OldAddress"].ToString();
        string strNewAddress = Session["NewAddress"].ToString();
        string strAction = Session["Action"].ToString();
        string strAdminName = Session["AdminUser"].ToString();
        string strLastName = Session["LastName"].ToString();
        string strCompany = Session["Agency"].ToString();
        string strDivisionOU = Session["DivisionOU"].ToString();
        bool blKeepAddress = (bool)Session["blKeepAddress"];

// remove leading and trailing spaces from input strings
        strAdminID = strAdminID.Trim();
        strUserDN = strUserDN.Trim();
        strLastName = strLastName.Trim();
        strCompany = strCompany.Trim();
        strOldAddress = strOldAddress.Trim();
        strAction = strAction.Trim();
        strAdminName = strAdminName.Trim();
        strDivisionOU = strDivisionOU.Trim();

//Find out what we are doing
        switch (strAction.ToLower())
        {
            case "create mailbox":
                fnCreateMailbox(strUserDN, strLastName, strCompany, strAdminName, strDivisionOU);
                break;
            case "delete mailbox":
                fnDeleteMailbox(strAdminID, strUserDN, strAdminName);
                break;
            case "change address":
                fnChangeAddress(strAdminID, strUserDN, strOldAddress, strNewAddress, strAdminName, strCompany, blKeepAddress);
                break;
        }
    }
    protected void fnCreateMailbox(string strUserDN, string strLastName, string strCompany, string strAdminName, string strDivisionOU)
    {
/*
* Function to create the mailbox
* Requires the user's ADsPath, Last Name, and Company (Agency)
*/
        string strAgency = "";
        string strKey = "";
        string strExchangeParam = "";

        int iLastNameNum = 0;

        Array arrExchParam;

        string strSubject = "";
        string strBody = "";
        string strAction = "";
    
        Collection<PSObject> colCreateResults;
        #region Scripting Dictionary
//Build the scripting dictionary for determining the server/storage group/database
        Dictionary<string, string> objDict = new Dictionary<string, string>();
        objDict.Add("ABC", "Server1:SG7:MBX7");
        objDict.Add("DEF", "Server2:SG7:MBX7");
        objDict.Add("AAS", "Server1:SG1:MBX1");
        objDict.Add("AAD", "Server1:SG2:MBX2");
        objDict.Add("DEP", "Server2:SG7:MBX7");
        objDict.Add("DSS", "Server3:SG5:MBX5");
        objDict.Add("DAD", "Server2:SG1:MBX1");
        objDict.Add("DSQ", "Server2:SG2:MBX2");
        objDict.Add("LOL", "Server3:SG4:MBX4");
        objDict.Add("BRB", "Server2:SG5:MBX5");
        objDict.Add("DNA", "Server2:SG6:MBX6");
        objDict.Add("MOD", "Server3:SG3:MBX3");
        objDict.Add("SOM", "Server3:SG4:MBX4");
        objDict.Add("MOM", "Server2:SG1:MBX1");
        objDict.Add("PAL", "Server3:SG6:MBX6");
        objDict.Add("HIT", "Server3:SG1:MBX1");
        objDict.Add("DOG", "Server3:SG2:MBX2");
        objDict.Add("CAE", "Server1:SG3:MBX3");
        objDict.Add("CAT", "Server1:SG4:MBX4");
        objDict.Add("ENA", "Server3:SG4:MBX4");
        objDict.Add("KAM", "Server2:SG3:MBX3");
        objDict.Add("MAK", "Server2:SG4:MBX4");
        objDict.Add("SJM", "Server2:SG7:MBX7");
        objDict.Add("TIK", "Server4:SG1:MBX1");
        objDict.Add("ILI", "Server4:SG2:MBX2");
        objDict.Add("OOP", "Server4:SG3:MBX3");
        objDict.Add("POW", "Server4:SG4:MBX4");
        objDict.Add("WQA", "Server4:SG5:MBX5");
        #endregion
        #region Agency Selector
        strAgency = strCompany.Trim().ToUpper();
        strKey = strAgency;
        #region HHS
        if (strAgency == "HHS")
        {
            iLastNameNum = Convert.ToInt16(Convert.ToChar(strLastName.Substring(0, 1).ToUpper()));
            if (iLastNameNum < 69)
            {
                strKey = strAgency + "1"; //Put A through D in 1st Storage Group
            }
            else if (iLastNameNum < 73)
            {
                strKey = strAgency + "2"; //Put E through H in 2nd Storage Group
            }
            else if (iLastNameNum < 77)
            {
                strKey = strAgency + "3"; //Put I through L in 3rd Storage Group
            }
            else if (iLastNameNum < 81)
            {
                strKey = strAgency + "4"; //Put M through P in 4th Storage Group
            }
            else if (iLastNameNum < 85)
            {
                strKey = strAgency + "5"; //Put Q through T in 5th Storage Group
            }
            else
            {
                strKey = strAgency + "6"; //Put U through Z in 6th Storage Group
            }
        }
        #endregion
        #region MDT
        if (strAgency == "MDT")
        {
            iLastNameNum = Convert.ToInt16(Convert.ToChar(strLastName.Substring(0, 1).ToUpper()));
            if (iLastNameNum < 70)
            {
                strKey = strAgency + "1"; //Put A through E in 1st Storage Group
            }
            else if (iLastNameNum < 75)
            {
                strKey = strAgency + "2"; //Put F through J in 2nd Storage Group
            }
            else if (iLastNameNum < 79)
            {
                strKey = strAgency + "3"; //Put K through N in 3rd Storage Group
            }
            else if (iLastNameNum < 84)
            {
                strKey = strAgency + "4"; //Put O through S in 4th Storage Group
            }
            else
            {
                strKey = strAgency + "5"; //Put T through Z in 5th Storage Group
            }
        }
        #endregion
        #region DLI
        if (strAgency == "DLI")
        {
            if (strDivisionOU == "BSD")
            {
                strKey = strAgency + "2"; //Put BSD in the 2nd Storage Group
            }
            else if (strDivisionOU == "CSD")
            {
                strKey = strAgency + "1"; //Put CSD in the 1st Storage Group
            }
            else if (strDivisionOU == "ERD")
            {
                strKey = strAgency + "2"; //Put ERD in 2nd Storage Group
            }
            else if (strDivisionOU == "JSD")
            {
                strKey = strAgency + "1"; //Put JSD in 1st Storage Group
            }
            else if (strDivisionOU == "RAD")
            {
                strKey = strAgency + "2"; //Put RAD in 2nd Storage Group
            }
            else if (strDivisionOU == "UID")
            {
                strKey = strAgency + "2"; //Put UID in 2nd Storage Group
            }
            else if (strDivisionOU == "WCC")
            {
                strKey = strAgency + "1"; //Put RAD in 1st Storage Group
            }
        }
        #endregion
        #region DOA
        if (strAgency == "DOA")
        {
            if (strDivisionOU == "ADM")
            {
                strKey = strAgency + "1"; //Put ADM in the 1st Storage Group
            }
            else if (strDivisionOU == "ITSD")
            {
                strKey = strAgency + "2"; //Put ITSD in 2nd Storage Group
            }
            else if (strDivisionOU == "MLOT")
            {
                strKey = strAgency + "1"; //Put MLOT in the 1st Storage Group
            }
            else if (strDivisionOU == "MPERA")
            {
                strKey = strAgency + "1"; //Put MPERA in 1st Storage Group
            }
            else if (strDivisionOU == "OPD")
            {
                strKey = strAgency + "2"; //Put OPD in 2nd Storage Group
            }
            else if (strDivisionOU == "TRS")
            {
                strKey = strAgency + "1"; //Put TRS in 1st Storage Group
            }
            else
            {
                strKey = strAgency + "4"; //Put others in 4th Storage Group
            }
        }
        #endregion
        #region COR DNR DOJ DOR FWP
        if ((strAgency == "COR") || (strAgency == "DNR") || (strAgency == "DOJ") || (strAgency == "DOR") || (strAgency == "FWP"))
        {
            iLastNameNum = Convert.ToInt16(Convert.ToChar(strLastName.Substring(0, 1).ToUpper()));
            if (iLastNameNum < 78)
            {
                strKey = strAgency + "1"; //Put A through M in 1st Storage Group
            }
            else
            {
                strKey = strAgency + "2"; //Put N through Z in 2nd Storage Group
            }
        }
        #endregion
        #endregion
        objDict.TryGetValue(strKey, out strExchangeParam);
        arrExchParam = strExchangeParam.Split(':');

        Response.Write("Mailbox Creation attempt for " + strUserDN + " on Exchange server " + arrExchParam.GetValue(0));
        {
// Verify that exchange specific AD properties exist, and set them if they don't
            strAction = "$user = [ADSI]^LDAP://" + strUserDN.Substring(1).Substring(0,strUserDN.Length -2) +"^";
            strAction = strAction.Replace("^", "\"");
            colCreateResults = runposh(strAction);
            strAction = "$attribute = $user.msExchVersion; if (!$attribute){$user.put('msExchVersion', '4535486012416')};$user.setinfo()";
            colCreateResults = runposh(strAction);
            strAction = "$attribute  = $user.msExchRecipientDisplayType; if (!$attribute){$user.put('msExchRecipientDisplayType', '1073741824')};$user.setinfo()";
            colCreateResults = runposh(strAction);
            strAction = "$attribute  = $user.msExchRecipientTypeDetails; if (!$attribute){$user.put('msExchRecipientTypeDetails', '1')};$user.setinfo()";
            colCreateResults = runposh(strAction);
//Now, create the mailbox            
            strAction = "Enable-Mailbox -identity " + strUserDN + " -Database " + arrExchParam.GetValue(0) + "\\" + arrExchParam.GetValue(1) + "\\" + arrExchParam.GetValue(2);
            colCreateResults = runposh(strAction);
            if (colCreateResults.Count > 0)
            {
//Disable Active Sync
                strAction = "Set-CASMailbox -identity " + strUserDN + " –ActiveSyncEnabled $false";
                colCreateResults = runposh(strAction);
                Response.Write("Mailbox creation was successful.<br /><br />");
                Response.Write("You will need to wait approximately 10 minutes for the mailbox to be available, due to Exchange and Active Directory replication latencies.<br /><br />");
                strSubject = strAdminName + " Created a mailbox";
                strBody = strAdminName + " created a mailbox associated with " + strUserDN + "\r\n\r\n";
                strBody = strBody + "This mailbox was created on " + arrExchParam.GetValue(0) + "\r\n\r\n";
                fnSendMail(strSubject, strBody);
            }
            else if (colCreateResults.Count == 0)
            {
                Response.Write("<br /><br />There was an error creating the mailbox. Please contact the Service Desk at x2000 to report this error. Include the logon ID of the user you were attempting to create the mailbox for, and any error shown below.<br /><br />");
                strAction = "$error[0]";
                colCreateResults = runposh(strAction);
                if (colCreateResults.Count > 0)
                {
                    string strErrorText = colCreateResults[0].ToString();
                    Response.Write("The error is: <b><span style='color:Red'>" + strErrorText + "</b></span><br />");
                }
                else if (colCreateResults.Count == 0)
                {
                    Response.Write("An unknown error occured.");
                }

            }
        }
    }
    protected void fnDeleteMailbox(string strAdminID, string strUserDN, string strAdminName)
    {
/*
* Function to Delete user's mailbox
* Requires the Admin ID and user's ADsPath
*/
// remove leading and trailing spaces from input strings
        strAdminID = strAdminID.Trim();
        strUserDN = strUserDN.Trim();
        strAdminName = strAdminName.Trim();

        Collection<PSObject> colDeleteResults;
        string strDeleteAction;
        Response.Write("Mailbox Deletion attempt for " + strUserDN);
        strDeleteAction = "$ConfirmPreference = 'none';set-Mailbox -Identity " + strUserDN + " -EmailAddresses $null -EmailAddressPolicyEnabled $false";
        colDeleteResults = runposh(strDeleteAction);
        strDeleteAction = "Disable-Mailbox -identity " + strUserDN + ";$ConfirmPreference = 'high'";
        colDeleteResults = runposh(strDeleteAction);
        if (colDeleteResults.Count == 0)
        {
            Response.Write("Mailbox deletion was successful.<br /><br /> You will need to wait approximately 10 minutes for the mailbox to disappear, due to Exchange and Active Directory replication latencies.");
            string strSubject = strAdminName + " Deleted a mailbox";
            string strBody = strAdminName + " deleted the mailbox associated with " + strUserDN;
            fnSendMail(strSubject, strBody);
        }
        else if (colDeleteResults.Count != 0)
        {
            Response.Write("There was an error disabling the mailbox. Please contact the ITSD Customer Support Center at x2000 to report this error. Include the logon ID of the user whose mailbox you were attemting to disable");
        }
    }
    protected void fnChangeAddress(string strAdminID, string strUserDN, string strOldAddress, string strNewAddress, string strAdminName, string strCompany, bool blKeepAddress)
    {
/*
* Function to change User's Primary SMTP Address
* Requires the user's ADsPath and desired address
*/

// remove leading and trailing spaces from input strings
        strAdminID = strAdminID.Trim();
        strUserDN = strUserDN.Trim();
        strOldAddress = strOldAddress.Trim();
        strNewAddress = strNewAddress.Trim();
        strAdminName = strAdminName.Trim();

        Collection<PSObject> colChangeResults;

        string strChangeAction = "";
        string strBody = "";
        string strSubject = "";

// First, findout if requested address is already in use
        strChangeAction = "Get-Recipient -Filter{EmailAddresses -eq '" + strNewAddress + "@domain.com'} |select Name";
        colChangeResults = runposh(strChangeAction);
        if (colChangeResults.Count == 0)
        {
// Requested address is available
            Response.Write("Your requested address, " + strNewAddress + "@domain.com, is available<br />");
// if blKeepAddress = false, delete old addresses in SMTP only
            if (blKeepAddress == false)
            {
                strChangeAction = "set-mailbox -identity " + strUserDN + " -PrimarySmtpAddress " + strNewAddress + "@domain.com -EmailAddressPolicyEnabled $false";
                colChangeResults = runposh(strChangeAction);
                do
                {
                    strChangeAction = "get-mailbox -identity " + strUserDN + " |select PrimarySmtpAddress";
                    colChangeResults = runposh(strChangeAction);
                } while (colChangeResults[0].ToString().Split('=')[1].Remove(colChangeResults[0].ToString().Split('=')[1].Length - 1).ToLower() != strNewAddress.ToLower() + "@domain.com");
                strChangeAction = "$mailbox = Get-Mailbox -identity " + strUserDN;
                colChangeResults = runposh(strChangeAction);
                strChangeAction = "$mailbox.EmailAddresses | foreach { if (!$_.IsPrimaryAddress -and ($_.PrefixString -eq 'SMTP')) {$mailbox.EmailAddresses -= $_}}";
                colChangeResults = runposh(strChangeAction); 
                strChangeAction = "start-sleep 5";
                colChangeResults = runposh(strChangeAction);
                strChangeAction = "set-mailbox -identity " + strUserDN + " -EmailAddresses $mailbox.EmailAddresses";
                colChangeResults = runposh(strChangeAction);    
            }
            else
            {
                strChangeAction = "set-mailbox -identity " + strUserDN + " -PrimarySmtpAddress " + strNewAddress + "@domain.com -EmailAddressPolicyEnabled $false";
                colChangeResults = runposh(strChangeAction);
            }

            Response.Write("We have changed the primary SMTP address on " + strUserDN + "<br />");
            Response.Write("From: " + strOldAddress + "<br />To: " + strNewAddress + "@domain.com<br />");
            Response.Write("Please allow approximately 10 minutes for this change to replicate.");
            strSubject = strOldAddress + " Address Change";
            strBody = "SMTP Address change from " + strOldAddress + " to " + strNewAddress + "@domain.com on " + strUserDN + " by " + strAdminName + "\r\n\r\n";
            fnSendMail(strSubject, strBody);
        }
        else if (colChangeResults.Count != 0)
        {
// Requested address is NOT available
            Response.Write("A duplicate address exists");
            Response.Write("Your requested address is: " + strNewAddress + "@domain.com<br />");
            string strFoundName = colChangeResults[0].ToString().Substring(7).Substring(0, colChangeResults[0].ToString().Length - 8);
            Response.Write("Duplicate address found at: " + strFoundName + "<br />");
        }
    }
    protected void fnSendMail(string strSubject, string strBody)
    {
// Send mail to postmaster
        MailMessage mail = new MailMessage();
        mail.From = new MailAddress("postmaster@domain.com");
        mail.To.Add(new MailAddress("postmaster@domain.com"));
        mail.Subject = strSubject;
        mail.Body = strBody;
        SmtpClient client = new SmtpClient();
        client.Host = "mail.domain.com";
        client.Send(mail);
    }
    protected Collection<PSObject> runposh(string strCommand)
    {
        Runspace rs = GetRunspace();
        Pipeline currentPipeline = GetPipeline(rs, strCommand);
        if (currentPipeline.PipelineStateInfo.State == PipelineState.NotStarted)
        {
            Collection<PSObject> results = currentPipeline.Invoke();
            currentPipeline.Dispose();
            Cache.Remove("currentPipe");
            return (results);
        }
        else
        {
            return null;
        }
    }
    protected Runspace GetRunspace()
    {
        if (Cache["rs"] == null)
        {
            Runspace rs = RunspaceFactory.CreateRunspace();
            rs.Open();
            Cache["rs"] = rs;
        }
        return (Runspace)Cache["rs"];
    }
    protected Pipeline GetPipeline(Runspace rs, string strCommand)
    {
        if (Cache["currentPipe"] == null)
        {
            Pipeline currentPipeline = rs.CreatePipeline(strCommand);
            Cache["currentPipe"] = currentPipeline;
        }
        return (Pipeline)Cache["currentPipe"];
    }
}
