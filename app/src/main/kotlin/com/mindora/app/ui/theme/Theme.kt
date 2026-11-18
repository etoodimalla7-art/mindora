package com.mindora.app.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.Typography
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.mindora.app.data.ThemeModeSetting

object MindoraPalette {
    // Brand — deep indigo with academic calm (from app_colors.dart)
    val Brand50 = Color(0xFFEEF2FF)
    val Brand100 = Color(0xFFE0E7FF)
    val Brand400 = Color(0xFF818CF8)
    val Brand500 = Color(0xFF6366F1)
    val Brand600 = Color(0xFF4F46E5)
    val Brand700 = Color(0xFF4338CA)

    // Accent — warm amber
    val Accent400 = Color(0xFFFBBF24)
    val Accent500 = Color(0xFFF59E0B)

    // Neutrals
    val Neutral0 = Color(0xFFFFFFFF)
    val Neutral50 = Color(0xFFF8FAFC)
    val Neutral100 = Color(0xFFF1F5F9)
    val Neutral200 = Color(0xFFE2E8F0)
    val Neutral400 = Color(0xFF94A3B8)
    val Neutral500 = Color(0xFF64748B)
    val Neutral700 = Color(0xFF334155)
    val Neutral800 = Color(0xFF1E293B)
    val Neutral900 = Color(0xFF0F172A)
    val Neutral950 = Color(0xFF020617)

    // Semantic
    val Success = Color(0xFF10B981)
    val Warning = Color(0xFFF59E0B)
    val Danger = Color(0xFFEF4444)
    val Info = Color(0xFF3B82F6)
}

private val LightColorScheme = lightColorScheme(
    primary = MindoraPalette.Brand600,
    onPrimary = MindoraPalette.Neutral0,
    primaryContainer = MindoraPalette.Brand50,
    onPrimaryContainer = MindoraPalette.Brand700,
    secondary = MindoraPalette.Accent500,
    onSecondary = MindoraPalette.Neutral950,
    error = MindoraPalette.Danger,
    onError = MindoraPalette.Neutral0,
    background = MindoraPalette.Neutral0,
    onBackground = MindoraPalette.Neutral900,
    surface = MindoraPalette.Neutral0,
    onSurface = MindoraPalette.Neutral900,
    surfaceVariant = MindoraPalette.Neutral50,
    onSurfaceVariant = MindoraPalette.Neutral500,
    outline = MindoraPalette.Neutral200,
    outlineVariant = MindoraPalette.Neutral200
)

private val DarkColorScheme = darkColorScheme(
    primary = MindoraPalette.Brand400,
    onPrimary = MindoraPalette.Neutral950,
    primaryContainer = Color(0xFF1E1B4B),
    onPrimaryContainer = MindoraPalette.Brand100,
    secondary = MindoraPalette.Accent500,
    onSecondary = MindoraPalette.Neutral950,
    error = MindoraPalette.Danger,
    onError = MindoraPalette.Neutral0,
    background = MindoraPalette.Neutral900,
    onBackground = MindoraPalette.Neutral50,
    surface = MindoraPalette.Neutral900,
    onSurface = MindoraPalette.Neutral50,
    surfaceVariant = MindoraPalette.Neutral800,
    onSurfaceVariant = MindoraPalette.Neutral400,
    outline = MindoraPalette.Neutral700,
    outlineVariant = MindoraPalette.Neutral700
)

private val MindoraTypography = Typography(
    headlineLarge = TextStyle(fontSize = 26.sp, fontWeight = FontWeight.Bold, lineHeight = 32.sp, letterSpacing = (-0.4).sp),
    headlineMedium = TextStyle(fontSize = 22.sp, fontWeight = FontWeight.SemiBold, lineHeight = 28.sp),
    headlineSmall = TextStyle(fontSize = 20.sp, fontWeight = FontWeight.SemiBold, lineHeight = 26.sp),
    titleLarge = TextStyle(fontSize = 18.sp, fontWeight = FontWeight.SemiBold, lineHeight = 24.sp),
    titleMedium = TextStyle(fontSize = 16.sp, fontWeight = FontWeight.SemiBold, lineHeight = 22.sp),
    titleSmall = TextStyle(fontSize = 14.sp, fontWeight = FontWeight.SemiBold, lineHeight = 20.sp),
    bodyLarge = TextStyle(fontSize = 16.sp, fontWeight = FontWeight.Normal, lineHeight = 24.sp),
    bodyMedium = TextStyle(fontSize = 14.sp, fontWeight = FontWeight.Normal, lineHeight = 21.sp),
    bodySmall = TextStyle(fontSize = 12.sp, fontWeight = FontWeight.Normal, lineHeight = 18.sp),
    labelLarge = TextStyle(fontSize = 14.sp, fontWeight = FontWeight.SemiBold, lineHeight = 18.sp),
    labelMedium = TextStyle(fontSize = 12.sp, fontWeight = FontWeight.SemiBold, lineHeight = 16.sp),
    labelSmall = TextStyle(fontSize = 11.sp, fontWeight = FontWeight.SemiBold, lineHeight = 14.sp)
)

private val MindoraShapes = Shapes(
    small = RoundedCornerShape(8.dp),
    medium = RoundedCornerShape(12.dp),
    large = RoundedCornerShape(16.dp),
    extraLarge = RoundedCornerShape(24.dp)
)

@Composable
fun MindoraTheme(
    themeMode: ThemeModeSetting = ThemeModeSetting.SYSTEM,
    content: @Composable () -> Unit
) {
    val isDark = when (themeMode) {
        ThemeModeSetting.SYSTEM -> isSystemInDarkTheme()
        ThemeModeSetting.LIGHT -> false
        ThemeModeSetting.DARK -> true
    }

    MaterialTheme(
        colorScheme = if (isDark) DarkColorScheme else LightColorScheme,
        typography = MindoraTypography,
        shapes = MindoraShapes,
        content = content
    )
}
