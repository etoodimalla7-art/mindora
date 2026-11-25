package com.mindora.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import com.mindora.app.data.MindoraStore
import com.mindora.app.ui.navigation.MindoraNavHost
import com.mindora.app.ui.theme.MindoraTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            val store = remember { MindoraStore(applicationContext) }
            val state by store.state.collectAsState()
            MindoraTheme(themeMode = state.themeMode) {
                MindoraNavHost(store = store)
            }
        }
    }
}
