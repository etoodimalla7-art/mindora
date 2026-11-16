import React from 'react';
import { MindoraProvider, useMindora } from './context/MindoraContext';
import { AppShell } from './components/Layout/AppShell';
import { WelcomeOnboardingScreen } from './components/Auth/WelcomeOnboardingScreen';
import { HomeDashboard } from './components/Home/HomeDashboard';
import { ReadinessDetailScreen } from './components/Progress/ReadinessDetailScreen';
import { AiTutorScreen } from './components/AI/AiTutorScreen';
import { PlannerScreen } from './components/Planner/PlannerScreen';
import { StudySessionView } from './components/Planner/StudySessionView';
import { LearnHubScreen } from './components/Learn/LearnHubScreen';
import { PastPapersScreen } from './components/Learn/PastPapersScreen';
import { DocumentUploadScreen } from './components/Learn/DocumentUploadScreen';
import { FlashcardsScreen } from './components/Learn/FlashcardsScreen';
import { MockExamsScreen, QuizzesScreen } from './components/Learn/QuizzesAndMockExamsScreen';
import { ProfileScreen } from './components/Profile/ProfileScreen';

const MindoraRouter: React.FC = () => {
  const { user, activeTab, subView } = useMindora();

  if (!user || !user.onboardingCompleted) {
    return <WelcomeOnboardingScreen />;
  }

  const renderContent = () => {
    if (subView.type === 'readiness') return <ReadinessDetailScreen />;
    if (subView.type === 'study_session') return <StudySessionView sessionId={subView.sessionId} />;
    if (subView.type === 'past_papers') return <PastPapersScreen />;
    if (subView.type === 'upload_document') return <DocumentUploadScreen initialView="upload" />;
    if (subView.type === 'my_contributions') return <DocumentUploadScreen initialView="mine" />;
    if (subView.type === 'flashcards') return <FlashcardsScreen />;
    if (subView.type === 'quizzes') return <QuizzesScreen />;
    if (subView.type === 'mock_exams') return <MockExamsScreen />;

    switch (activeTab) {
      case 'home':
        return <HomeDashboard />;
      case 'ai':
        return <AiTutorScreen />;
      case 'planner':
        return <PlannerScreen />;
      case 'learn':
        return <LearnHubScreen />;
      case 'profile':
        return <ProfileScreen />;
      default:
        return <HomeDashboard />;
    }
  };

  return <AppShell>{renderContent()}</AppShell>;
};

export const App: React.FC = () => {
  return (
    <MindoraProvider>
      <MindoraRouter />
    </MindoraProvider>
  );
};

export default App;
