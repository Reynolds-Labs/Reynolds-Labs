# LAB 001 --- Role-Based User Provisioning with Custom Skeleton Profiles

**Platform:** Rocky Linux 10.1\
**Focus:** Linux administration, Bash automation, role-based access
control, custom SKEL profiles, KDE integration, SELinux-aware
deployment, and validation.

## Overview

LAB001 builds a repeatable onboarding system for three fictional
employee classes: a standard employee, Human Resources, and Special
Projects. Instead of manually creating and configuring every account,
each role receives a reusable custom skeleton profile containing the
folders, onboarding material, desktop resources, launchers, branding,
and configuration appropriate to that role.

Linux groups and protected shared directories provide authorization
boundaries. SELinux remains in Enforcing mode throughout the lab.

The final phase adds an administrator-facing **AutoUser** workflow. An
administrator chooses a role, enters the employee information, reviews
the provisioning summary, and authorizes account creation. The same
provisioning logic can then be reused for many accounts without
rebuilding each workstation profile by hand.

> All employee names, records, missions, and business data shown in this
> lab are synthetic.

## Problem

Manual Linux onboarding does not scale well. Creating a user account is
quick, but repeatedly creating the correct folders, resources,
permissions, desktop configuration, documentation, and role access is
slow and error-prone.

The goal was to turn that repeated work into a controlled provisioning
process while preserving least-privilege access.

## Architecture

``` text
                         Rocky Linux 10.1
                               |
                    Reynolds Labs LAB001
                               |
              +----------------+----------------+
              |                |                |
          Base SKEL          HR SKEL        Agent SKEL
              |                |                |
        Standard users       rlab_hr        rlab_agents
              |                |                |
              |          Protected HR     Protected Agent
              |             resources        resources
              |                |                |
              +------ Least-Privilege Isolation -------+
                               |
                       SELinux Enforcing
                               |
                        AutoUser Front End
                               |
             +-----------------+-----------------+
             |                 |                 |
          Add Basic          Add HR           Add Agent
             |                 |                 |
             +------- reusable Bash provisioning -------+
```

The initial Rocky Linux environment was verified before configuring the role-based provisioning system.

![Rocky Linux baseline environment](screenshots/01-rocky-baseline.png)

Custom skeletons were kept separate from the global `/etc/skel`:

``` text
/opt/reynolds-labs/lab001/skel/base
/opt/reynolds-labs/lab001/skel/hr
/opt/reynolds-labs/lab001/skel/agent
```

Protected role data was separated under `/srv` and assigned to dedicated
Linux groups:

``` text
/srv/reynolds-labs/lab001/hr       -> rlab_hr
/srv/reynolds-labs/lab001/agents   -> rlab_agents
```

The protected directories use SGID group inheritance and restrictive
group-based permissions so that role membership determines access.

## Automated Provisioning

The final version of LAB001 adds three administrator-facing provisioning
choices:

-   **Add Basic User**
-   **Add HR User**
-   **Add Agent User**

The administrator-facing launchers provide a consistent entry point for the three provisioning workflows.

![AutoUser provisioning launchers](screenshots/14-autouser-launchers.png)

The GUI launchers call role-specific Bash provisioning logic. The
administrator supplies the identity information instead of manually
recreating the account configuration.

The Agent workflow demonstrates the complete process particularly well.

![Agent automation input](screenshots/15-agent-automation-input.png)

The administrator enters the Linux username, employee name, and
fictional codename. Before creating the account, the workflow presents a
provisioning summary showing the role, profile, Linux group, and
skeleton that will be applied.

![Agent automation summary](screenshots/16-agent-automation-summary.png)

For the demonstrated account, the workflow selected the Special Projects
profile, `rlab_agents` authorization group, and Agent custom skeleton.

After authorization, the provisioning process can create the account and
home directory from the reusable role template, apply role membership,
personalize the welcome material, restore appropriate ownership/SELinux
labeling, configure authentication, and prepare the account for first
login.

The important scaling concept is that the **role configuration is built
once and reused**. If an organization needed to onboard 50 users with
the same role, the administrator would not need to manually recreate 50
folder structures and workstation profiles. The same provisioning
workflow could be run repeatedly with different employee identities. For
larger production environments, the same design could be extended to
batch input, centralized identity management, or
configuration-management tooling.

### Automation proof

A newly provisioned fictional Agent account, `rlab_agent02`, was created
for Hunter Pepperbrook with codename Mango. On first login, the account
received the expected Special Projects workstation, personalized welcome
file, role, account identity, resources, and Agent-specific desktop
environment.

![Automated Agent proof](screenshots/17-agent-automation-proof.png)

This demonstrates the full chain:

``` text
Administrator
     |
     v
AutoUser role launcher
     |
     v
Role-specific provisioning script
     |
     +--> validates requested account
     +--> creates Linux user/home
     +--> selects custom SKEL profile
     +--> assigns required Linux group
     +--> personalizes role resources
     +--> applies ownership / SELinux contexts
     +--> configures authentication
     |
     v
Ready-to-use role workstation
```

## Role-Based Access Control

The lab separates authorization from workstation appearance. Receiving
an HR or Agent desktop is not what grants access; Linux group membership
controls access to the protected shared resources.

![Role permissions](screenshots/03-role-based-directory-permissions.png)

A standard employee has neither protected role group:

![Standard user denied](screenshots/07-standard-user-access-denied.png)

An HR employee can access the HR resource:

![HR authorized](screenshots/09-hr-authorized-access.png)

A Special Projects employee can access the Agent resource:

![Agent authorized](screenshots/11-agent-authorized-access.png)

Cross-role testing confirmed that an Agent account cannot simply browse
the HR resource:

![Agent denied HR](screenshots/12-agent-cross-role-denied.png)

## Reusable Workstation Profiles

### Standard employee

![Standard workstation](screenshots/06-standard-workstation.png)

The Base profile provides standard documents, training, templates, and
workstation resources without granting access to HR or Special Projects
data.

### Human Resources

The HR skeleton directory contains the files and folders that are copied into newly provisioned HR workstations.

![Custom HR skeleton structure](screenshots/04-custom-hr-skeleton.png)

![HR workstation](screenshots/08-hr-workstation.png)

The HR skeleton provides standardized HR resources and integrates the
user with the protected HR share through `rlab_hr`.

A second fictional HR employee was provisioned to test whether the
profile was genuinely reusable rather than being built only for the
first account.

![Repeatable HR
provisioning](screenshots/13-repeatable-hr-provisioning.png)

### Special Projects

The separate Agent skeleton demonstrates how the same provisioning system can deploy a different role-specific starting environment.

![Custom Agent skeleton structure](screenshots/05-custom-agent-skeleton.png)

![Agent workstation](screenshots/10-agent-workstation.png)

The fictional Agent profile deliberately uses a different visual
identity and resource structure while relying on the same underlying
Linux provisioning concepts.

## SELinux

SELinux remained **Enforcing** during the lab.

![SELinux enforcing](screenshots/02-selinux-enforcing.png)

After role-specific files were deployed into user home directories,
`restorecon` was used so files received contexts consistent with system
policy. The lab did not disable SELinux to make the provisioning process
work.

## Troubleshooting and Iteration

Several issues discovered during the build improved the final design.

**Desktop environment assumptions.** Early desktop launchers assumed
Nautilus, but the Rocky workstation was running KDE Plasma with Dolphin.
Launching was changed to use desktop-agnostic behavior.

**Desktop Entry path handling.** `%h` was treated literally by KDE
rather than as a home-directory substitution. Folder-opening logic was
moved into a small helper rather than embedding increasingly complicated
shell quoting in `.desktop` files.

**KDE autostart.** A conventional autostart entry did not reliably
execute the role profile in this Plasma environment. The implementation
was changed to KDE's native `~/.config/autostart-scripts/` mechanism.

**Reusable templates.** The original HR skeleton contained a welcome
file personalized for the first HR employee. Provisioning a second HR
employee exposed that design flaw. The profile was refactored to use a
generic welcome template with placeholders that are personalized during
provisioning.

These failures were useful because they forced the lab to move from a
one-user demonstration toward a genuinely reusable design.

## Validation

The lab validated:

-   Rocky Linux baseline and user defaults
-   SELinux Enforcing state
-   dedicated Linux groups for protected roles
-   SGID/restrictive permissions on shared resources
-   custom Base, HR, and Agent skeletons
-   authorized HR access
-   authorized Agent access
-   standard-user denial
-   cross-role denial
-   creation of a second HR employee from the reusable profile
-   administrator-facing provisioning launchers
-   automated creation and first login of an additional Agent account

## What This Lab Demonstrates

This project demonstrates practical experience with Linux user and group
administration, filesystem permissions, least privilege, custom skeleton
directories, Bash automation, KDE desktop integration, SELinux-aware
file deployment, validation, troubleshooting, and technical
documentation.

It is intentionally a lab-scale design. In a production environment I
would evaluate centralized identity services, stronger secrets/password
onboarding, audit logging, batch/CSV or API-driven provisioning,
configuration management, and lifecycle operations such as automated
offboarding.

## Evidence

The `screenshots/` directory contains the curated build and validation
evidence used in this write-up.

## Disclosure

This is an independently built portfolio lab. All names, employee
records, organizational data, and Special Projects content are
fictional/synthetic. No proprietary employer code, credentials, customer
information, or production data are included.

---

## After Thoughts — Behind the Build

I wanted to start Reynolds Labs with this project because I had previously worked with custom commands and Linux skeleton directories (`/etc/skel`) and saw an opportunity to turn that knowledge into a real-world example. While a larger organization would most likely use something like LDAP or another centralized identity management system, I wanted to showcase how you could automate user provisioning on a local Linux system. The idea was simple: select the user, choose the profile they need, and boom, they're done. Their folders, permissions, and workstation resources would already be configured. Most of my Linux experience hadn't involved much account provisioning because I'm usually the main user of my home lab systems. I don't typically need an entire identity management system, but I could see how this approach would be useful for creating different work environments while protecting resources that certain users shouldn't access. This lab was a fun way to explore Linux permissions and account management, and like most things in IT, I figured it would be even better if I could automate it.

Like most labs, I ran into a few unexpected issues along the way. The actual user provisioning, folder creation, and permissions were fairly straightforward, but getting everything to work automatically with KDE Plasma was another story. I had issues with custom desktop backgrounds and other workstation settings not applying the way I intended. Some of my original scripts also assumed I was using Nautilus, when the system was actually running KDE Plasma with Dolphin. That required some adjustments to how the desktop launchers worked. I also had to make changes to the provisioning scripts because not everything was showing up correctly when a new user logged in. One issue I discovered while testing another HR account was that some of the welcome information was still tied to the original user, so I had to make the templates more reusable. Looking back, creating the Linux accounts was probably the easiest part of the project. Getting the automation to consistently build the correct environment for each user was where most of the work came in.

Looking back at this lab, I would say one of the biggest lessons was the importance of testing early and testing more than one scenario. It's fairly easy to configure one or two users manually, but if you were responsible for onboarding 30 employees, you would definitely want an automated process. I learned that getting something working for one user doesn't necessarily mean it will work correctly for everyone else. If I were starting this project again, I would spend more time testing the individual profiles and scripts before putting everything together into the automated provisioning system. That probably would have saved some troubleshooting later on. I also gained a better understanding of how Linux groups and permissions can separate users and protect resources without needing an overly complicated setup.

I could see myself revisiting this project in a future lab and combining it with a centralized identity management system such as FreeIPA. That would be an interesting way to expand the project beyond local user accounts and explore how organizations manage users across multiple Linux systems. I could also see pairing it with Ansible to handle more of the configuration and reduce the amount of manual scripting. Both would be good opportunities to take what I learned here and build something closer to an enterprise environment.

---

## Reynolds Labs — Lab Assessment

**Technical Skill:** 1/5 — Basic  
**Fun Factor:** 1/5 — Minimal

![Reynolds Labs LAB001 Assessment](screenshots/lab001-assessment.png)
