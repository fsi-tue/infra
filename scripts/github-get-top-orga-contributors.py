#!/usr/bin/env python3
# Dependencies: PyGithub (https://github.com/PyGithub/PyGithub)

from github import Github

print("""To avoid hitting API rate limits this script requires a GitHub token.
You can generate a personal token here: https://github.com/settings/tokens/new
No additional rights/scopes are required but "read:org" is useful to get the
private members (if you're a member of fsi-tue).
""")

token = input("Enter your token: ")
if token == "":
    token = None
    print("Attempting to run without a token (expect hitting the rate limits).")
g = Github(token)
print()

orga = g.get_organization("fsi-tue")
repos = orga.get_repos()
users = {}

for repo in repos:
    print(repo.name)
    contributors = repo.get_contributors()
    for contributor in contributors:
        name = contributor.login
        if contributor.name:
            name = name + " (" + contributor.name + ")"
        print("- " + name + ": " + str(contributor.contributions))
        if contributor in users:
            users[contributor] += contributor.contributions
        else:
            users[contributor] = contributor.contributions

print()
print("Total:")
for user, contributions in sorted(users.items(), key=lambda kv: kv[1], reverse=True):
    name = user.login
    if user.name:
        name = name + " (" + user.name + ")"
    print("- " + name + ": " + str(contributions))

fsi_tue = g.get_organization("fsi-tue")
org_members = fsi_tue.get_members()

print()
print("Total (fsi-tue only):")
fsi_users = {}
for user in org_members:
    if user in users:
        fsi_users[user] = users[user]
    else:
        fsi_users[user] = 0
for user, contributions in sorted(fsi_users.items(), key=lambda kv: kv[1], reverse=True):
    name = user.login
    if user.name:
        name = name + " (" + user.name + ")"
    print("- " + name + ": " + str(contributions))
