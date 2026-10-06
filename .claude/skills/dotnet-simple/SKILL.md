---
name: dotnet-simple
description: Use for EVERY C# / .NET change in this repo — controllers, models, request DTOs, repositories, Program.cs, appsettings. Encodes the plain, beginner-readable C# style the owner (a senior Angular dev learning .NET) requires, the project structure, and copy-ready templates. Read before writing or reviewing any C#.
---

# Plain C# for TheMorisakiBookshop.api

The owner is learning .NET by reading this code. Every line must be readable by someone who
knows TypeScript well and C# a little. When two ways work, pick the one with fewer concepts.

## Structure

```
Controllers/BaseController.cs        route = api/[controller]/[action]
Controllers/Shop/<Name>Controller.cs         public read endpoints
Controllers/Management/<Name>ManagementController.cs   write endpoints
Models/CustomActionResult.cs         response envelope without data (see "Response envelope")
Models/CustomActionResultOfT.cs      response envelope with data: CustomActionResult<T>
Models/<Name>OutputModel.cs          shape of a row returned by a stored procedure / sent to the UI
Models/Dto/<Name>RequestModel.cs     shape of a request body (with validation attributes)
Repositories/<Table>Repository.cs    calls stored procedures with Dapper (skill sql-server-dapper)
Database/Migrations/NNNN_*.sql       SQL scripts (skill sql-server-dapper)
Program.cs                           service registration + middleware
```

Flow: Controller → Repository → stored procedure; the controller wraps the result in
`CustomActionResult<T>`. No service layer, no interfaces with a single
implementation, no mappers, no base repository, no generic helpers.

## Naming

| Thing | Convention | Example |
|---|---|---|
| Namespace, class, method, property, enum, constant | PascalCase | `BooksRepository`, `GetByIdAsync`, `MaxPageSize` |
| Parameter, local variable | camelCase | `authorId`, `book` |
| Private field | `_camelCase` | `_booksRepository` |
| Interface (rare, see below) | `I` + PascalCase | `IPriceCalculator` |
| Async method | `Async` suffix | `GetByIdAsync` |
| Request body model | `RequestModel` suffix | `CreateBookRequestModel` |
| Row / response model | `OutputModel` suffix | `BookOutputModel` |
| Internal-only model | `Model` suffix | `BookPriceModel` |
| File | exactly the type name | `CreateBookRequestModel.cs` |

Existing files with old names (`Books`, `CreateBookRequest`, ...) are renamed when their task touches them.

## Rules

Always:
- **One type per file**, file name = type name. One controller per file.
- Block-scoped namespace: `namespace TheMorisakiBookshop.Repositories { ... }` (as existing code).
- Explicit types: `BookOutputModel book = ...`, `List<BookOutputModel> books = ...`. `var` only when the right side is `new SomeType(...)`.
- Braces on every `if` / `else` / `foreach`, even one-liners.
- Full-word names: `booksRepository`, not `repo` / `br`. Private fields `_camelCase`, `readonly`.
- Constructor injection, assigned to a `readonly` field in a normal constructor.
- `async Task<...>` all the way down; async method names end with `Async`.
- Every async method takes `CancellationToken cancellationToken` as its last parameter and passes it on.
  Controller actions get it for free from ASP.NET (cancelled when the browser aborts the request —
  like unsubscribing from an `HttpClient` Observable).
- Collections are `List<T>` in every method signature — not `IEnumerable<T>`, not arrays.
- Never return `null` for a collection — return an empty `List<T>`. A single item may be `null` (`BookOutputModel?`) = not found.
- Models are plain `class`es with `{ get; set; }` properties and default values (`= "";`, `= new List<T>();`).
- Methods short (~30 lines) and doing one thing. Early `return` instead of deep nesting.
- `if` / `else` and `foreach` instead of clever expressions.
- Comments: short, explain *why*, only where it isn't obvious. Teaching goes in the chat, not in comments.

Never:
- Expression-bodied members (`public int X() => 5;`, `public string Name => _name;`) — write a normal body with `return`.
- Lambdas, except where a framework API requires one (e.g. `AddCors(options => ...)` in Program.cs).
- LINQ (`Where`, `Select`, `OrderBy`, `Any`, query syntax...). Filtering/sorting/joining is done in the stored procedure. Only allowed: `.ToList()` on a Dapper result.
- Switch expressions, property/list patterns (`is { Length: > 0 }`), `??=`, nested ternaries, `?.` chains.
- Primary constructors, records, `required`, `init`, collection expressions (`[1, 2]`), target-typed `new()` when the type isn't on the same line, tuples, deconstruction, local functions, `dynamic`, `out var`, `using var` (use a `using (...) { }` block), top-level statements.
- Our own generics (the one exception is `CustomActionResult<T>`), extension methods, attributes, reflection, static "Utils" classes, inheritance (other than `BaseController`).
- New NuGet packages without asking her (no AutoMapper, MediatR, FluentValidation, EF Core...).

If an existing file breaks these rules and you touch it, fix the part you touch and mention it.

## Response envelope — `CustomActionResult` (mandatory)

Every endpoint returns the same JSON shape. The Angular side (`ApiResponse<T>` in `ApiHelperService`)
depends on it:
```json
{ "isSuccess": true, "data": { ... }, "message": null, "errors": [] }
```
(ASP.NET writes property names in camelCase, so `IsSuccess` becomes `isSuccess`.)

```csharp
// Models/CustomActionResult.cs — for endpoints with no data (delete, update)
namespace TheMorisakiBookshop.Models
{
    public class CustomActionResult
    {
        public bool IsSuccess { get; set; }
        public string? Message { get; set; }
        public List<string> Errors { get; set; } = new List<string>();
    }
}
```
```csharp
// Models/CustomActionResultOfT.cs — for endpoints that return data
namespace TheMorisakiBookshop.Models
{
    public class CustomActionResult<T>
    {
        public bool IsSuccess { get; set; }
        public T? Data { get; set; }
        public string? Message { get; set; }
        public List<string> Errors { get; set; } = new List<string>();
    }
}
```
`<T>` is a generic — like `Array<T>` / `Observable<T>` in TypeScript: `CustomActionResult<BookOutputModel>`
carries one book, `CustomActionResult<List<BookOutputModel>>` carries a list.

Rules:
- Every controller action returns `Ok(result)` where `result` is a `CustomActionResult` or `CustomActionResult<T>`.
  **Always HTTP 200 for business outcomes** — "not found", "not allowed", "already exists" are
  `IsSuccess = false` + a friendly `Message`, not `NotFound()` / `BadRequest()`.
- Build it with an object initializer: `new CustomActionResult<T> { IsSuccess = true, Data = data }`.
- Success with a list: `Data` is the list (empty list when nothing found, never null).
- Repositories return plain models (`BookOutputModel?`, `List<BookOutputModel>`); only controllers create envelopes.
- Non-200 only from the framework, and with the same envelope body:
  - 400 — validation failed (`[Required]` etc.): `Errors` = the validation messages (configured once in Program.cs, below).
  - 500 — unexpected exception: `Message = "An unexpected error occurred."` (global exception handler in Program.cs).

Program.cs setup (lambdas are allowed here because the framework API requires them):
```csharp
builder.Services.AddControllers()
    .ConfigureApiBehaviorOptions(options =>
    {
        // Validation errors use the same envelope as every other response.
        options.InvalidModelStateResponseFactory = context =>
        {
            CustomActionResult result = new CustomActionResult();
            result.IsSuccess = false;
            result.Message = "The request is not valid.";

            foreach (KeyValuePair<string, ModelStateEntry> entry in context.ModelState)
            {
                foreach (ModelError error in entry.Value.Errors)
                {
                    result.Errors.Add(error.ErrorMessage);
                }
            }

            return new BadRequestObjectResult(result);
        };
    });
```
```csharp
app.UseExceptionHandler(handler =>
{
    handler.Run(async context =>
    {
        CustomActionResult result = new CustomActionResult();
        result.IsSuccess = false;
        result.Message = "An unexpected error occurred.";

        context.Response.StatusCode = StatusCodes.Status500InternalServerError;
        await context.Response.WriteAsJsonAsync(result);
    });
});
```
(needs `using Microsoft.AspNetCore.Mvc;`, `using Microsoft.AspNetCore.Mvc.ModelBinding;`, `using TheMorisakiBookshop.Models;`)

## Templates

### Output model (one row from a stored procedure)
```csharp
namespace TheMorisakiBookshop.Models
{
    public class AuthorOutputModel
    {
        public int Id { get; set; }
        public string Name { get; set; } = "";
        public string Image { get; set; } = "";
    }
}
```

### Request DTO (one per file)
```csharp
using System.ComponentModel.DataAnnotations;

namespace TheMorisakiBookshop.Models.Dto
{
    public class CreateAuthorRequestModel
    {
        [Required]
        [MinLength(1)]
        public string Name { get; set; } = "";

        public string Image { get; set; } = "";
    }
}
```
`[ApiController]` (on `BaseController`) returns 400 automatically when validation fails — like
Angular `Validators`, but enforced on the server.

### Controller
```csharp
using Microsoft.AspNetCore.Mvc;
using TheMorisakiBookshop.Models;
using TheMorisakiBookshop.Repositories;

namespace TheMorisakiBookshop.Controllers.Shop
{
    public class AuthorsController : BaseController
    {
        private readonly AuthorsRepository _authorsRepository;

        public AuthorsController(AuthorsRepository authorsRepository)
        {
            _authorsRepository = authorsRepository;
        }

        [HttpGet]
        public async Task<IActionResult> GetAuthorById(int id, CancellationToken cancellationToken)
        {
            AuthorOutputModel? author = await _authorsRepository.GetByIdAsync(id, cancellationToken);

            if (author == null)
            {
                return Ok(new CustomActionResult<AuthorOutputModel>
                {
                    IsSuccess = false,
                    Message = $"Author with id {id} not found."
                });
            }

            return Ok(new CustomActionResult<AuthorOutputModel>
            {
                IsSuccess = true,
                Data = author
            });
        }

        [HttpGet]
        public async Task<IActionResult> GetAllAuthors(CancellationToken cancellationToken)
        {
            List<AuthorOutputModel> authors = await _authorsRepository.GetAllAsync(cancellationToken);

            return Ok(new CustomActionResult<List<AuthorOutputModel>>
            {
                IsSuccess = true,
                Data = authors
            });
        }
    }
}
```
- Keep the existing route style: `[HttpGet]` for reads, `[HttpPost]` for writes, action name in the URL.
- Controller = call repository, wrap the result in a `CustomActionResult`, return `Ok(...)`. No SQL, no business logic.
- Building a model from a request: assign property by property (see `BooksManagementController`), no mapper.

### Registration in Program.cs
```csharp
builder.Services.AddScoped<AuthorsRepository>();
```
`AddScoped` = one instance per HTTP request (repositories open a connection per call, so scoped is right).

### Repository
See skill `sql-server-dapper` — it owns the Dapper pattern.

## Before you finish
- `dotnet build` passes with no new warnings.
- Every new file contains exactly one type, named per the Naming table.
- Every action returns `Ok(...)` with a `CustomActionResult` / `CustomActionResult<T>` — no `NotFound()`, `NoContent()`, `CreatedAtAction()`, no raw models.
- Every async method has `Async` suffix and a `CancellationToken`; no `IEnumerable`/array/null collections in signatures.
- Re-read your diff against the "Never" list.
- New concept used? Explain it in chat with the Angular equivalent and add it to `.claude/memory/LEARNING.md`.
