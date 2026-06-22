# Random User Coding Challenge

## Task

You are working for a company showing random users information (RandomUser Inc.). As a good company based on random users data, they want to show random information about random users.

Your task for this code test is to design an Android/iOS application (the one you prefer) with these requirements:

- Download a list of random users from the `randomuser.me` API.
- Be careful, some users can be duplicated. You should take this into account and **not** show duplicated users. If the Random User API returns the same user more than once, you have to store just one user inside your system.
- Show a list of random users with this information:
  - User name and surname.
  - User email.
  - User picture.
  - User phone.
- Add a button or any similar infinite scroll mechanism to retrieve more users and add them to your current users list.
- Add a button to each cell (or a similar interaction) to delete users. If you press that button, the user will not be shown anymore in your user list — even if the user is part of a new server-side response.
- Your user interface should contain a textbox to filter users by name, surname or email. Once the user stops typing, the list will be updated with users that match the search term.
- If you press a cell, you have to show another view with the user's detailed information:
  - User gender.
  - User name and surname.
  - User location: street, city and state.
  - Registered date.
  - User email.
  - User picture.
- The user information should be persistent across application sessions.
  - That means that if I open the application for the first time and I see "John Smith" as the first contact, I should always see the same contact in that position until I remove it or uninstall the application, no matter how many times I relaunch the app.
- Test your code. Think about the most important parts of your application and write tests.
- Try to solve this code test like a real-life project. Think about the architecture and design of your model, and try to implement it as modular as possible.
- At the same time, don't over-engineer your project. Find a good balance between modularization and readability.

## API Description

You can obtain a list of random users at this URL: `http://api.randomuser.me/?results=40`. The full documentation of the API is available at: `https://randomuser.me/documentation`.

API JSON response sample:

```json
{
  "results": [
    {
      "gender": "male",
      "name": {
        "title": "mr",
        "first": "lee",
        "last": "fuller"
      },
      "location": {
        "street": "2450 victoria road",
        "city": "dundee",
        "state": "derbyshire",
        "postcode": "W7 7ES"
      },
      "email": "lee.fuller@example.com",
      "login": {
        "username": "ticklishgorilla350",
        "password": "memorex",
        "salt": "yZqPeuEP",
        "md5": "e8b9f7f3e44cd89cb237336ba7831df1",
        "sha1": "3c8e5f933eb033ec5493b9e347e9071760da8cc7",
        "sha256": "afa9c23c2ef814ce839762a1148e05c8cfcee463140f4759ac55545fe717fd6a"
      },
      "dob": "1993-12-02 22:36:31",
      "registered": "2003-01-14 03:11:16",
      "phone": "0161 818 9583",
      "cell": "0783-416-873",
      "id": {
        "name": "NINO",
        "value": "ZL 04 28 54 L"
      },
      "picture": {
        "large": "https://randomuser.me/api/portraits/men/63.jpg",
        "medium": "https://randomuser.me/api/portraits/med/men/63.jpg",
        "thumbnail": "https://randomuser.me/api/portraits/thumb/men/63.jpg"
      },
      "nat": "GB"
    }
  ]
}
```

> Note: this sample reflects an older version of the API. The live API response differs in shape — `location.street` is now an object (`{ number, name }`), `dob` and `registered` are objects (`{ date, age }`) with ISO8601 dates, and `login` includes a `uuid`. Verify against `https://randomuser.me/api/?results=5` before modeling.

## What we look for

- This task is designed to give an idea of how you think when faced with a limited amount of time to solve a task of significant complexity. You will need to prioritize what you feel is important.
- The overall look and feel of the application is important. Do your best to use the appropriate platform frameworks.
- We are also interested in how you structure your code so that it's easily extendable, complies with best OO practices, and is easy to modify/understand by others.
- Special attention will be paid to your tests. Write them carefully and stay focused on the most important parts of your application.
- If you base the application architecture on existing templates/projects, make sure you adapt it to the test's needs (e.g. remove anything that doesn't make sense). In any case, give proper credit to the existing code.

## Submitting your solution

Hand in your solution along with any notes, comments and assumptions you have made while working on it, via email to the person who sent you this test.

Delivery will be done by uploading the code to a public git repository system like GitHub or Bitbucket. Or, if you prefer, bundle all files into a zip (with the local git repository inside). Remember to use descriptive commit messages.

This technical test is **not** time-boxed, but time is taken into consideration just as any other factor when reviewing your solution.