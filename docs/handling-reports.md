# Process of handling a security report

> **Note**: this is a work-in-progress document, more coming soon!

1. First, you'll receive an email to `security@rust-lang.org`. Some spam comes
   to this email address sometimes, it can be disregarded.
2. Messages may be encrypted with our GPG key. The private key is stored in
   Rust's 1password instance. You can request access to the key or you can wait
   for another member to decrypt and share the information amongst the WG.
3. The report should be determined if it's credible or not. Either way, a
   response should be sent the the reporter relatively soon (we try to be
   ASAP-ish). It's fine to say we continue to investigate.
4. Now comes the fun part, discussing the vulnerability! (assuming it needs more
   investigation and hasn't been ruled out).

Discussing the vulnerability can range from being extremely sensitive to "fine
to try to keep it private for now". There's a few venues that the response can
be discussed at:

* First, you can use `security@rust-lang.org`. This may or may not include the
  original reporter. Keep in mind that email clients have varying degrees of
  caching and such, super sensitive stuff should always be encrypted. You get to
  always choose who sees what here, but it's not a great medium to develop with
  or make public later.

* Next you can use the `#security` channel in Discord. Keep in mind the core
  team can see messages here as well. Users (like the reporter) cannot be added
  here.

* We've also started to test out using GitHub Advisories. This is on the
  "security" tab on GitHub. Keep in mind the core team can see all messages here
  as well. You can add anyone to the conversation here on the bug (including the
  reporter).

Over the next few days you'll develop a response to the security issue in these
venues, and it's recommended to do this in collaboration with the original
reporter as well. They like to be kept in the loop and can often help out in
validating fixes and such!

Eventually you'll have a desired response and a date will be set for the
announcement. We do not have a procedure for creating a *release* prior to the
announcement at this time. Past procedure has been to make point releases and
patches available soon after an announcement. Depending on the severity of the
report we may need to figure out how to do private releases ahead of time.

If we consider the vulnerability's severity to be medium or higher we need to
post it to distros@lists.openwall.com **3 days** before the public
announcement. [Read the instructions on how to do that carefully][distros], as
they're pretty strict on what they want.

When publishing an announcement, this should include:

* Send mail to the google group mailing list. This should be the first thing
  done. Documentation on how to do so is available later in this document.

* Make a post to the blog. Use the same content, but add a disclaimer that it's
  not official and point to the google group mail.

* Make a post to users.rust-lang.org containing the same contents as the blog.

* Publish the GitHub Advisory, also with a disclaimer that points to the blog.

* Send an email to oss-security@lists.openwall.com with a brief excerpt of the
  advisory and the link to the google group mail. [Instructions on how to send
  an email to oss-security@][oss-security]

[distros]: https://oss-security.openwall.org/wiki/mailing-lists/distros#list-policy-and-instructions-for-reporters
[oss-security]: https://oss-security.openwall.org/wiki/mailing-lists/oss-security

## Disclosing a vulnerability on the rustlang-security-announcements Google Group

This procedure was tested on a Linux system.

1. Import the security public key in your local GPG keychain, to be able to
   later ensure the signature is valid:

   ```
   curl https://www.rust-lang.org/static/keys/rust-security-team-key.gpg.ascii | gpg --import
   ```

2. Copy the announcement in a local text file named `announcement.txt`. Add the
   following sentence at the start of the report:

   > Note: if you're reading this advisory on the Google Groups web interface
   > please note that the GPG signature doesn't match, due to the processing
   > Google Groups does to the message. You can find a signed copy of this
   > advisory attached.

3. Sign the message with the security team's key. The command should be
   executed inside this repository. You need to provide your 1password
   credentials when prompted.

   ```
   ./with-rust-security-key.sh gpg --clearsign announcement.txt
   ```

4. Verify the signature is correct:

    ```
    gpg --verify announcement.txt.asc
    ```

5. Send a mail to rustlang-security-announcements@googlegroups.com from your
   personal email address with the content of `announcement.txt.asc` as the
   message body. Also attach `announcement.txt.asc` to the same mail.
