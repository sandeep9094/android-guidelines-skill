---
name: android-guidelines
description: Guidelines and instructions for Android development, including SDK design patterns (entry point, environment, exceptions, logging) and Jetpack Compose resource management (strings, colors, typography, themes, dimensions, icons).
---

# Android Guidelines

This skill documents the standard architecture for creating robust, testable, and highly decoupled Android SDK modules, using the generic entry point structure, environments, exceptions, logging systems, and Jetpack Compose resource management.

## 1. Generic Entry Point Design Pattern

To keep the SDK clean and encapsulate the construction of internal classes (managers, collectors, preferences, etc.), use the **Public Interface + Internal Implementation** pattern with a single entry point class.

### Public SDK Interface (`NetworkSDK`)

- The main SDK class should have an `internal constructor` so the host application cannot instantiate it directly.
- Provide a `Companion object` with a thread-safe singleton pattern (`getInstance()`) to retrieve the initialized instance.
- Expose all public APIs by delegating them to an internal implementation wrapper class.
- Use a static nested `Builder` class to configure and initialize the SDK.

```kotlin


class NetworkSDK internal constructor(internal val impl: NetworkSdkImpl) {

    @Throws(SDKException::class)
    fun activate() = impl.activate()

    fun release() = impl.release()

    companion object {
        @Volatile
        private var _instance: NetworkSDK? = null

        fun getInstance(): NetworkSDK =
            _instance ?: throw IllegalStateException("SDK is not initialized. Call Builder.build() first.")

        fun getInstanceOrNull(): NetworkSDK? = _instance

        internal fun clearInstance() {
            _instance = null
        }
    }

    class Builder(context: Context) {
        private val appContext: Context = context.applicationContext
        private var config = SdkConfig()

        fun setDeviceId(deviceId: String) = apply { config = config.copy(deviceId = deviceId) }
        fun setApiKey(apiKey: String?) = apply { config = config.copy(apiKey = apiKey) }

        @Throws(SDKException::class)
        fun build(): NetworkSDK {
            _instance?.let { return it }
            return synchronized(NetworkSDK::class.java) {
                _instance ?: buildInternal().also { _instance = it }
            }
        }

        private fun buildInternal(): NetworkSDK {
            val deviceId = DeviceIdValidator.validate(config.deviceId)
            val apiKey = ApiKeyValidator.validate(config.apiKey)

            val impl = NetworkSdkImpl(
                context = appContext,
                config = config.copy(deviceId = deviceId, apiKey = apiKey)
            )
            return NetworkSDK(impl)
        }
    }
}
```

### Internal Implementation (`NetworkSdkImpl`)

- The implementation class is marked `internal class` to keep it out of the public auto-import and API package scope of the host application.
- It instantiates and wires together helper modules, managers, collectors, and logging classes.
- Maintains the lifecycle status of the SDK (e.g. `isActivated` flag).

---

## 2. App Environment Design Pattern

Use a centralized `AppEnv` configuration class containing standard endpoint URLs, debug switches, and environment modes (e.g. UAT, Staging, Production). This shields internal modules from checking build types or hardcoding settings.

```kotlin

import androidx.annotation.Keep

object AppEnv {
    private var current: SdkProductFlavours = SdkProductFlavours.UAT
    
    val BASE_URL: String
        get() = current.baseUrl

    val LOGGING_ENABLED: Boolean
        get() = current.loggingEnabled
}

enum class SdkProductFlavours(
    val baseUrl: String,
    val loggingEnabled: Boolean
) {
    UAT(
        baseUrl = "http://129.154.245.136:5050",
        loggingEnabled = true
    )
}
```

---

## 3. SDK Exception Framework

Define standard error codes and wrap all expected SDK runtime and configuration failures into a single `SDKException` class to allow host apps to gracefully handle error paths.

```kotlin
import androidx.annotation.Keep

@Keep
object SDKErrorCode {
    const val MISSING_DEVICE_ID = 1001
    const val INVALID_DEVICE_ID = 1002
    const val MISSING_API_KEY   = 1003
    const val INVALID_API_KEY   = 1004
    const val MISSING_PERMISSIONS = 1005
    const val DEVICE_REGISTRATION = 1006
}
```

```kotlin
import androidx.annotation.Keep

@Keep
class SDKException(
    val errorCode: Int,
    message: String
) : Exception(message)
```

---

## 4. SDK Logging Pattern

Avoid using raw `Log.d` / `Log.e` calls. Wrap platform logging in a central `SDKLog` helper utility.
- Prefixes every log message with the SDK Name (e.g., `NetworkConfigurator: `).
- Checks `AppEnv.LOGGING_ENABLED` to prevent logs leaking in release/production builds.
- Uses inline functions with lambda message arguments (`message: () -> String`) to prevent string formatting and allocation overhead when logging is disabled.

```kotlin
import android.util.Log
import androidx.annotation.Keep

@Keep
internal object SDKLog {
    private val _isEnabled: Boolean = AppEnv.LOGGING_ENABLED
    internal const val PREFIX = "NetworkConfigurator: "
    internal val isEnabled = _isEnabled

    inline fun d(tag: String, message: () -> String) {
        if (isEnabled) {
            Log.d(PREFIX + tag, message())
        }
    }
    
    // ... Additional i, w, e, v methods ...
}
```

---

## 5. Jetpack Compose Resource Management Guidelines

With the rise of Jetpack Compose as the go-to UI toolkit for Android development, managing resources like strings, colors, fonts, and dimensions in a consistent, scalable manner is crucial for building maintainable and efficient applications. While Jetpack Compose offers a fresh approach to UI development, best practices for resource management still follow principles of separation, reusability, and ease of localization.

### Managing Strings for Localization
Store all static strings in `res/values/strings.xml` for easier localization and to avoid hardcoded strings.

```xml
<!-- strings.xml -->
<resources>
    <string name="app_name">My Compose App</string>
    <string name="welcome_message">Welcome to Jetpack Compose!</string>
</resources>
```

Access these strings using the `stringResource()` function in your Compose code:

```kotlin
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource

@Composable
fun WelcomeMessage() {
    Text(text = stringResource(id = R.string.welcome_message))
}
```

### Defining and Using Colors
Centralize color definitions for consistency and reusability by defining them in a Kotlin file or referencing XML color resources.

#### Best Practice: Define Colors in a `Color.kt` File
```kotlin
import androidx.compose.ui.graphics.Color

val PrimaryColor = Color(0xFF6200EE)
val PrimaryLightColor = Color(0xFFBB86FC)
val PrimaryDarkColor = Color(0xFF3700B3)
val AccentColor = Color(0xFF03DAC5)
```

Use these colors in composables:
```kotlin
Text(text = "Hello", color = PrimaryColor)
```

#### Alternative: XML-based colors for backwards compatibility
```xml
<!-- colors.xml -->
<resources>
    <color name="primaryColor">#6200EE</color>
    <color name="primaryLightColor">#BB86FC</color>
</resources>
```

Access with `colorResource()`:
```kotlin
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.colorResource

val primaryColor = colorResource(id = R.color.primaryColor)
```

### Typography and Font Management
Define fonts and text styles in a centralized manner to ensure consistent typography.

#### Best Practice: Define a `Typography.kt` File
```kotlin
import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

val Roboto = FontFamily(
    Font(R.font.roboto_regular),
    Font(R.font.roboto_bold, FontWeight.Bold)
)

val AppTypography = Typography(
    bodyLarge = TextStyle(
        fontFamily = Roboto,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp
    ),
    displayLarge = TextStyle(
        fontFamily = Roboto,
        fontWeight = FontWeight.Bold,
        fontSize = 24.sp
    )
)
```

Apply these styles in composables:
```kotlin
Text(text = "Heading", style = AppTypography.displayLarge)
```

### Using Themes for Colors, Typography, and Shapes
Centralize colors, typography, and shapes configuration via `MaterialTheme`.

#### Best Practice: Define a Custom Theme
Create a `Theme.kt` file:
```kotlin
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

@Composable
fun MyAppTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = lightColorScheme(
            primary = PrimaryColor,
            secondary = AccentColor
        ),
        typography = AppTypography,
        shapes = Shapes,
        content = content
    )
}
```

### Managing Dimensions (Padding, Margins, Sizes)
Define consistent spacing and sizes centrally.

#### Best Practice: Define Dimensions in a `Dimens.kt` File
```kotlin
import androidx.compose.ui.unit.dp

val PaddingSmall = 8.dp
val PaddingMedium = 16.dp
val PaddingLarge = 24.dp
```

Apply in UI components:
```kotlin
Box(modifier = Modifier.padding(PaddingMedium)) {
    // Content here
}
```

#### Alternative: Using `dimens.xml`
```xml
<resources>
    <dimen name="padding_small">8dp</dimen>
    <dimen name="padding_medium">16dp</dimen>
</resources>
```
Access using `dimensionResource()`:
```kotlin
val padding = dimensionResource(id = R.dimen.padding_small)
```

### Icon Management in Compose
Use vector assets or Material Icons.

#### Best Practice: Use Material Icons
```kotlin
import androidx.compose.material3.Icon
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home

Icon(imageVector = Icons.Filled.Home, contentDescription = "Home Icon")
```

## 6. Kotlin & Jetpack Compose Coding Style

- **No Fully Qualified Names (FQCN):** Never use inline fully qualified package names in code blocks (e.g., avoid `androidx.compose.ui.graphics.Brush...`, `androidx.compose.foundation.layout.Box...`).
- **Explicit Imports:** Always declare standard `import` statements at the top of the file for all Compose classes, functions, and modifier extensions (e.g., `import androidx.compose.ui.graphics.Brush`).
- **Clean Call-sites:** Reference classes directly by their simple name (e.g., `Brush.horizontalGradient(...)`).

---

## 7. Android Architecture & Jetpack Compose Feature Guidelines

Always enforce strict file and architectural separation for any Jetpack Compose feature tasks. Do NOT bundle UI State, ViewModel, and Composable screens into a single file.

### 7.1 File Organization & Package Structure

Every feature must reside in its own package under `feature/<feature_name>/` and split across separate files:

| File | Purpose |
|:-----|:--------|
| `<Feature>UiState.kt` | Immutable `data class` or `sealed interface` representing the UI state |
| `<Feature>ViewModel.kt` | `@HiltViewModel`-annotated class managing state via `StateFlow` and business logic |
| `<Feature>Screen.kt` | Composable UI split into a stateful entry composable and a stateless previewable composable |
| `components/` | Sub-package for granular, reusable screen-specific composables |

**Example package layout:**
```
feature/
└── login/
    ├── LoginUiState.kt
    ├── LoginViewModel.kt
    ├── LoginScreen.kt
    └── components/
        ├── LoginButton.kt
        └── LoginTextField.kt
```

### 7.2 Implementation Rules

#### State Separation (`<Feature>UiState.kt`)
- Define `UiState` in its own dedicated file.
- Use `@Immutable` or `@Stable` annotations where appropriate.

```kotlin
import androidx.compose.runtime.Immutable

@Immutable
data class LoginUiState(
    val email: String = "",
    val password: String = "",
    val isLoading: Boolean = false,
    val errorMessage: String? = null
)
```

#### ViewModel Lifecycle (`<Feature>ViewModel.kt`)
- Annotate with `@HiltViewModel` and inject via `@Inject constructor`.
- Collect flows using `.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), InitialState)`.
- Expose state as `StateFlow`, never as mutable `LiveData` or raw `MutableStateFlow` to the UI.

```kotlin
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import javax.inject.Inject

@HiltViewModel
class LoginViewModel @Inject constructor(
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(LoginUiState())
    val uiState: StateFlow<LoginUiState> = _uiState
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = LoginUiState()
        )

    fun onEmailChanged(email: String) {
        _uiState.update { it.copy(email = email) }
    }

    fun onPasswordChanged(password: String) {
        _uiState.update { it.copy(password = password) }
    }

    fun onLoginClicked() {
        // business logic here
    }
}
```

#### Stateless UI (`<Feature>Screen.kt`)
- Split every screen into two composables:
  1. **Stateful entry composable** — injects the ViewModel via `hiltViewModel()`, collects state, forwards events.
  2. **Stateless previewable composable** — accepts direct state and lambda callbacks only. No ViewModel reference.
- Never pass `ViewModel` instances down to child composables. Hoist all events to lambda parameters.

```kotlin
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle

// Stateful entry — only this composable knows about the ViewModel
@Composable
fun LoginScreen(
    onLoginSuccess: () -> Unit,
    viewModel: LoginViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    LoginContent(
        uiState = uiState,
        onEmailChanged = viewModel::onEmailChanged,
        onPasswordChanged = viewModel::onPasswordChanged,
        onLoginClicked = viewModel::onLoginClicked
    )
}

// Stateless & previewable — no ViewModel, no side-effects
@Composable
fun LoginContent(
    uiState: LoginUiState,
    onEmailChanged: (String) -> Unit,
    onPasswordChanged: (String) -> Unit,
    onLoginClicked: () -> Unit
) {
    // UI implementation here
}

@Preview(showBackground = true)
@Composable
private fun LoginContentPreview() {
    LoginContent(
        uiState = LoginUiState(email = "test@example.com"),
        onEmailChanged = {},
        onPasswordChanged = {},
        onLoginClicked = {}
    )
}
```

### 7.3 Code Output Convention

When generating or modifying code for a feature, always provide **distinct code blocks labeled with the exact file path**, for example:

```
// feature/login/LoginUiState.kt
// feature/login/LoginViewModel.kt
// feature/login/LoginScreen.kt
// feature/login/components/LoginButton.kt
```

---

## 8. UI Strings vs. Internal Business Logic

### Rule Summary

| Type | Where it belongs | Example |
|:-----|:----------------|:--------|
| User-facing display text | `res/values/strings.xml` | Button labels, screen titles, error messages shown in UI |
| Internal constants & templates | `InternalConstants.kt` | CSV headers, API keys, format strings, config values |
| Domain-type strings | `enum class` with a `title` property | Transaction types, status codes, category names |

### 8.1 UI Strings — `res/values/strings.xml`

Only user-facing text displayed inside Jetpack Compose widgets should be localized:

```xml
<!-- res/values/strings.xml -->
<resources>
    <string name="label_income">Income</string>
    <string name="label_expense">Expense</string>
    <string name="error_invalid_amount">Please enter a valid amount</string>
</resources>
```

```kotlin
// Used inside a composable only
Text(text = stringResource(R.string.label_income))
```

### 8.2 Internal Constants — `InternalConstants.kt`

Strings used for business logic, data formatting, or configuration must **never** go in `strings.xml`. Place them in a centralized object as the single source of truth:

```kotlin
// util/InternalConstants.kt
object InternalConstants {

    // CSV import/export
    object Csv {
        val EXPECTED_HEADERS = listOf("Date", "Amount", "Type", "Category", "Note")
        const val DATE_FORMAT = "dd/MM/yyyy"
        const val DELIMITER = ","
    }

    // API / Network
    object Api {
        const val BASE_URL = "https://api.example.com/v1/"
        const val TIMEOUT_SECONDS = 30L
    }
}
```

### 8.3 Enum Type Safety

Never use raw string comparisons for domain logic. Always represent defined types with an `enum class`:

```kotlin
// ❌ Wrong — fragile raw string comparison
if (transaction.type == "Income") { ... }

// ✅ Correct — type-safe enum with a display title
enum class TransactionType(val title: String) {
    INCOME("Income"),
    EXPENSE("Expense"),
    TRANSFER("Transfer");

    companion object {
        fun fromTitle(title: String): TransactionType =
            entries.firstOrNull { it.title.equals(title, ignoreCase = true) }
                ?: throw IllegalArgumentException("Unknown transaction type: $title")
    }
}

// Usage in business logic
if (transaction.type == TransactionType.INCOME) { ... }

// Safe parsing from raw data (e.g., CSV or API response)
val type = TransactionType.fromTitle(rawCsvValue)
```

---

## 9. Compose Single Responsibility Principle (SRP)

### 9.1 One Entity Per File

A Kotlin file should represent exactly **one** single conceptual entity. Never define multiple distinct UI widgets in the same file.

```
// ❌ Wrong — multiple unrelated composables in one file
// TransactionScreen.kt
fun TransactionScreen() { ... }
fun DetailRow() { ... }       // ← should be its own file
fun HeaderCard() { ... }      // ← should be its own file
```

### 9.2 Extract Components into `components/`

If a screen uses distinct sub-widgets, extract each into its own file inside a `components/` sub-package within the feature folder:

```
feature/
└── transaction/
    ├── TransactionUiState.kt
    ├── TransactionViewModel.kt
    ├── TransactionScreen.kt       ← orchestrates components
    └── components/
        ├── DetailRow.kt           ← single widget, own file
        ├── HeaderCard.kt          ← single widget, own file
        └── AmountBadge.kt         ← single widget, own file
```

Each component file contains exactly one composable (plus its `@Preview`):

```kotlin
// feature/transaction/components/DetailRow.kt
import androidx.compose.runtime.Composable
import androidx.compose.ui.tooling.preview.Preview

@Composable
fun DetailRow(
    label: String,
    value: String
) {
    // implementation
}

@Preview(showBackground = true)
@Composable
private fun DetailRowPreview() {
    DetailRow(label = "Category", value = "Groceries")
}
```

### 9.3 When to Extract

Extract a composable into its own file when **any** of the following are true:

- It is used in more than one screen
- It has its own meaningful visual identity (card, row, badge, chart)
- Its own `@Preview` would be useful for design review
- It would make `Screen.kt` exceed ~150 lines of UI code
