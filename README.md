# CODING STANDARDS (made in 10 minutes) FOR DRAWFI: 

## 1 Naming conventions: 

- camelCase (loanScreen) for naming functions. 
- snake_case (auth_screen) for naming files. 

## 2. Code organization and structure: 

- When you make a file, make sure it goes in the right folder. Example: Screen files go in the screen folder. 

- Each function or class should only have one responsibility. Don't include data or functionality that doesn't make sense or that is not a part of the class. 

- Utility functions get their own file. 


## 3. Commenting and Documentation. 

- Add comments on every function (///) 

- TODO's to show things we might need to change or next steps. 

## 4. Error handling. 

- print() messages are the best. 

## 5. Code consistency and style. 

- Make widgets or write function as small and short as possible. 

- We will use trailing commas. 

```dart
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: _buildAuthScreen(isSmallScreen),
            ),
          );
```

## 6. Third party libraries and tools

- Use libraries when we need them. 

## 7. Testing. 

- Keep doing "test ups" (step by step) a.k.a. bottom-up testing/building. 


## 8. Dead code and refactoring. 

- Comment if there is some code that is not used. 

- Use other strategies as needed. 

## 9. Commit messages. 

- Commit when you make a significant change. 

- Push when you're sure it isn't going to break. 

- Pull when you first get onto your computer. 

## 10. AI and External Code Usage. 

- ALWAYS UNDERSTAND AI GENERATED CODE *BEFORE* YOU PUT IT IN. 

- Write a comment of what it does when you put it in. 


