# Apache Fineract Security Reports

<!--
Copyright ©2025 The Apache Software Foundation.

Licensed under the Apache License, Version 2.0 (the "License"); you may not use
this file except in compliance with the License. You may obtain a copy of the
License at

https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed
under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
CONDITIONS OF ANY KIND, either express or implied. See the License for the
specific language governing permissions and limitations under the License.
-->

This page lists all security vulnerabilities fixed in released versions of Apache Fineract. Each vulnerability is reported via [the ASF process](http://www.apache.org/security/) and given a security impact rating.

If you have identified a security issue, let us know immediately via email to security AT fineract.apache.org. And be sure to [secure your Fineract server](https://fineract.apache.org/docs/current/#_securing_fineract)!

## Fixed in Apache Fineract 1.12.1

### [CVE-2025-58137](https://www.cve.org/CVERecord?id=CVE-2025-58137): auth bypass through user-controlled key

Authorization Bypass Through User-Controlled Key vulnerability in Apache Fineract.

------- --------
Report  2024-10-07
Fix     2025-05-16
Affects 1.11.0 and earlier releases
------- --------

Thank you Peter Chen with PayPal Security for identifying the issue.
Thank you Ádám Sághy, Aleksandar Vidakovic, and Victor Romero for fixing it.

### [CVE-2025-58130](https://www.cve.org/CVERecord?id=CVE-2025-58130): insufficiently protected credentials

Insufficiently Protected Credentials vulnerability in Apache Fineract.

------- --------
Report  2024-10-07
Fix     2025-04-14
Affects 1.11.0 and earlier releases
------- --------

Thank you Peter Chen with PayPal Security for identifying the issue.
Thank you Jose Alberto Hernandez and Ádám Sághy for fixing it.

## Fixed in Apache Fineract 1.11.0

### [CVE-2025-23408](https://www.cve.org/CVERecord?id=CVE-2025-23408): weak password policy

Weak Password Requirements vulnerability in Apache Fineract.

------- --------
Report  2024-10-07
Fix     2024-11-11
Affects 1.10.1 and earlier releases
------- --------

Thank you Peter Chen with PayPal Security for identifying the issue.
Thank you Kristof Jozsa with BaaSFlow for fixing it.

## Fixed in Apache Fineract 1.10.1

### [CVE-2024-32838](https://www.cve.org/CVERecord?id=CVE-2024-32838): SQL injection - various

SQL Injection vulnerability in various API endpoints - offices, dashboards, etc. Apache Fineract versions 1.9 and before have a vulnerability that allows an authenticated attacker to inject malicious data into some of the REST API endpoints' query parameter. Users are recommended to upgrade to version 1.10.1, which fixes this issue. A SQL Validator has been implemented which allows us to configure a series of tests and checks against our SQL queries that will allow us to validate and protect against nearly all potential SQL injection attacks.

------- --------
Report  2024-04-18
Fix     2024-05-01
Affects 1.9.0 and earlier releases
------- --------

We acknowledge Kabilan S - Security engineer at Zoho, for identifying the issue and Aleksandar for resolving it.

## Fixed in Apache Fineract 1.9.0

### [CVE-2024-23539](https://www.cve.org/CVERecord?id=CVE-2024-23539): vulnerable endpoints

Under certain system configurations, the sqlSearch parameter for specific endpoints was vulnerable to SQL injection attacks, potentially allowing attackers to manipulate database queries.

Fixed by <https://github.com/apache/fineract/pull/3621>.

------- --------
Report  2023-09-04
Fix     2023-12-06
Affects 1.8.4 and earlier releases
------- --------

We thank Yash Sancheti of GH Solutions Consultants for reporting this issue.

### [CVE-2024-23538](https://www.cve.org/CVERecord?id=CVE-2024-23538): SQL injection - sqlSearch

Under certain system configurations, the sqlSearch parameter was vulnerable to blind SQL injection attacks, potentially allowing attackers to manipulate database queries.

Fixed by <https://github.com/apache/fineract/pull/3626>.

------- --------
Report  2023-08-09
Fix     2023-12-06
Affects 1.8.4 and earlier releases
------- --------

We thank Majd Alasfar of ProgressSoft for reporting this issue.

### [CVE-2024-23537](https://www.cve.org/CVERecord?id=CVE-2024-23537): privilege escalation

Under certain circumstances, this vulnerability allowed users, without specific permissions, to escalate their privileges to any role, including super user status. This flaw could enable users to gain control over user management.

Fixed by <https://github.com/apache/fineract/pull/3626>.

------- --------
Report  2023-09-04
Fix     2023-12-06
Affects 1.8.4 and earlier releases
------- --------

We thank Yash Sancheti of GH Solutions Consultants for reporting this issue.

## Fixed in Apache Fineract 1.8.4 and 1.7.3

### [CVE-2023-25197](https://www.cve.org/CVERecord?id=CVE-2023-25197): SQL injection

Improper Neutralization of Special Elements used in an SQL Command ('SQL Injection') vulnerability in Apache Software Foundation apache fineract.

------- --------
Report
Fix
Affects 1.8.3 and earlier releases
------- --------

We would like to thank Eugene Lim at Cyber Security Group (CSG) Government Technology Agency GOVTECH.sg, for reporting this issue, and the Apache Security team for their assistance. Thank you to Aleksandar Vidakovic for resolving this CVE.

### [CVE-2023-25196](https://www.cve.org/CVERecord?id=CVE-2023-25196): SQL injection

Improper Neutralization of Special Elements used in an SQL Command ('SQL Injection') vulnerability in Apache Software Foundation Apache Fineract. Authorized users may be able to change or add data in certain components.

------- --------
Report  2022-12-02
Fix     2023-03-01
Affects 1.8.3 and earlier releases
------- --------

We would like to thank Zhang Baocheng at Leng Jing Qi Cai Security Lab, for reporting this issue, and the Apache Security team for their assistance. Thank you to aleks@apache.org for resolving this CVE.

### [CVE-2023-25195](https://www.cve.org/CVERecord?id=CVE-2023-25195): SSRF

Server-Side Request Forgery (SSRF) vulnerability in Apache Software Foundation Apache Fineract. Authorized users with limited permissions can gain access to server and may be able to use server for any outbound traffic.

------- --------
Report  2022-12-06
Fix     2023-03-01
Affects 1.8.3 and earlier releases
------- --------

We would like to thank Huydoppa from GHTK, for reporting this issue, and the Apache Security team for their assistance. Thank you to Aleks@apache.org for resolving this CVE.

## Fixed in Apache Fineract 1.8.1 and 1.7.1

### [CVE-2022-44635](https://www.cve.org/CVERecord?id=CVE-2022-44635): file upload vulnerability

Apache Fineract allowed an authenticated user to perform remote code execution due to a path traversal vulnerability in a file upload component of Apache Fineract, allowing an attacker to run remote code. This issue affects Apache Fineract version 1.8.0 and prior versions. We recommend users to upgrade to 1.8.1.

Under typical deployments, remote code could be run.

------- --------
Report  2022-10-31
Fix     2022-11-22
Affects 1.8.0 and earlier releases
------- --------

We would like to thank Sapra co-captain of the Super Guesser CTF team & Security researcher at CRED, for reporting this issue, and the Apache Security team for their assistance. We give kudos and karma to Aleksandar Vidakovic for resolving this CVE.

## Fixed in Apache Fineract 1.5.0

### [CVE-2020-17514](https://www.cve.org/CVERecord?id=CVE-2020-17514): disabled hostname verification for HTTPS

Apache Fineract disables HTTPS hostname verification in `ProcessorHelper` in the `configureClient` method.

Under typical deployments, a man in the middle attack could be successful.

------- --------
Report  2020-10-15
Fix     2020-10-19
Affects 1.4.0 and earlier releases
------- --------

We would like to thank [Simon Gerst](https://github.com/intrigus-lgtm) for reporting this issue, and the Apache Security team for their assistance.

## Fixed in Apache Fineract 1.4.0

### [CVE-2018-20243](https://www.cve.org/CVERecord?id=CVE-2018-20243): unencrypted username and password in URL

The implementation of POST with the username and password in the URL parameters exposed the credentials. More information is available in Fineract JIRA issues 726 and 629.

------- --------
Report  2018-12-31
Fix     2020-01-01
Affects 1.3.0 and earlier releases
------- --------

We would like to thank [Simon Gerst](https://github.com/intrigus-lgtm) for reporting this issue, and the Apache Security team for their assistance.

## Fixed in Apache Fineract 1.3.0

### [CVE-2018-11801](https://www.cve.org/CVERecord?id=CVE-2018-11801): SQL Injection - m_center

SQL injection vulnerability in Apache Fineract before 1.3.0 allows attackers to execute arbitrary SQL commands via a query on a m_center data related table.

------- --------
Report  2018-08-29
Fix     2018-12-01
Affects 1.2.0 and earlier releases
------- --------

We would like to thank Niels Heinen from Google for reporting this issue, and the Apache Security team for their assistance.

### [CVE-2018-11800](https://www.cve.org/CVERecord?id=CVE-2018-11800): SQL Injection - GroupSummaryCounts

SQL injection vulnerability in Apache Fineract before 1.3.0 allows attackers to execute arbitrary SQL commands via a query on the GroupSummaryCounts related table.

------- --------
Report  2018-08-29
Fix     2018-12-01
Affects 1.2.0 and earlier releases
------- --------

We would like to thank Niels Heinen from Google for reporting this issue, and the Apache Security team for their assistance.

### [CVE-2016-4977](https://www.cve.org/CVERecord?id=CVE-2016-4977): RCE as a result of CVE in upstream dependency

A known vulnerability in spring security upstream dependencies allowed malicious users to trigger remote code execution.

------- --------
Report  2018-12-17
Fix     2019-02-01
Affects 1.2.0 and earlier releases
------- --------

We would like to thank Roberto (extranewbugs@gmail.com) for reporting this issue, and the Apache Security team for their assistance.

## Fixed in Apache Fineract 1.1.0

### [CVE-2018-1292](https://www.cve.org/CVERecord?id=CVE-2018-1292): SQL Injection - reportName

Within the 'getReportType' method, a hacker could inject SQL to read/update data for which he doesn't have authorization for by way of the 'reportName' parameter.

------- --------
Report  2018-01-23
Fix     2018-04-19
Affects 1.0.0 and earlier releases
------- --------

We would like to thank 圆珠笔 (627963028@qq.com) and the Apache Security team for reporting this issue.

### [CVE-2018-1291](https://www.cve.org/CVERecord?id=CVE-2018-1291): SQL Injection - order

Apache Fineract exposes different REST end points to query domain specific entities with a Query Parameter 'orderBy' which are appended directly with SQL statements. A hacker/user can inject/draft the 'orderBy' query parameter by way of the "order" param in such a way to to read/update the data for which he doesn't have authorization.

------- --------
Report  2018-01-23
Fix     2018-04-19
Affects 1.0.0 and earlier releases
------- --------

We would like to thank 圆珠笔 (627963028@qq.com) and the Apache Security team for reporting this issue.

### [CVE-2018-1290](https://www.cve.org/CVERecord?id=CVE-2018-1290): SQL Injection - single quotation escape

Using a single quotation escape with two continuous SQL parameters can cause a SQL injection. This could be done in Methods like retrieveAuditEntries of AuditsApiResource Class retrieveCommands of MakercheckersApiResource Class

------- --------
Report  2018-01-23
Fix     2018-04-19
Affects 1.0.0 and earlier releases
------- --------

We would like to thank 圆珠笔 (627963028@qq.com) and the Apache Security team for reporting this issue.

### [CVE-2018-1289](https://www.cve.org/CVERecord?id=CVE-2018-1289): SQL Injection - orderBy and sortOrder

Apache Fineract exposes different REST end points to query domain specific entities with a Query Parameter 'orderBy' and 'sortOrder' which are appended directly with SQL statements. A hacker/user can inject/draft the 'orderBy' and 'sortOrder' query parameter in such a way to read/update the data for which he doesn't have authorization.

------- --------
Report  2018-01-18
Fix     2018-04-19
Affects 1.0.0 and earlier releases
------- --------

We would like to thank 圆珠笔 (627963028@qq.com) and the Apache Security team for reporting this issue.

## Fixed in Apache Fineract 1.0.0

### [CVE-2017-5663](https://www.cve.org/CVERecord?id=CVE-2017-5663): SQL Injection - sqlSearch

An authenticated user with client/loan/center/staff/group read permissions is able to inject malicious SQL into SELECT queries. The 'sqlSearch' parameter on a number of endpoints is not sanitized and appended directly to the query. List of vulnerable endpoints: /staff, /clients, /loans, /centers, /groups.

------- --------
Report  2017-04-02
Fix     2017-12-13
Affects 0.6.0-incubating and earlier releases
------- --------

We would like to thank Alex Ivanov and the Apache Security team for reporting this issue.

## Notable Fineract security policy updates

- January 15, 2025: The project now determines on a case by case basis whether a CVE fix will be back-ported to any prior release. The default is that all prior releases are immediately determined as EOL (end of life) when a new release happens.
- November 29, 2022: In order to ensure that users are given warning of critical issues, the Apache Fineract project may use its relationship with the independent Mifos Initiative to ensure that users of the Fineract backend and Mifos front end UI are informed of such vulnerabilities and are able to assist in testing and validating patches.

## Editing this document

The source for this document is [plain text with minimal Pandoc-flavor Markdown](https://pandoc.org/MANUAL.html#pandocs-markdown).
It is [rendered as HTML with Pandoc](https://github.com/apache/fineract-site/tree/asf-site/src/security).

Keep this document simple and consistent.
If you change the structure for one section, do so throughout the document.

Major headings are releases in descending order (most recent first). Minor headings are CVE ids, also in descending order. Always use `www.cve.org` for canonical CVE links. Date format for "Report" and "Fix" fields is `YYYY-MM-DD`.
