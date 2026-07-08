import { useEffect } from 'react';
import { useLinks } from '@utils/useLinks';
import { useAuth } from '@contexts/AuthContext.jsx';
import { useUserSettings } from '@utils/useUserSettings.js';
import FullscreenLoader from '@newtab/components/FullscreenLoader.jsx';
import Header from '@components/Header';
import Main from '@newtab/components/Main.jsx';


export default function App() {
  const { user, authReady } = useAuth();
  const { loading: linksLoading } = useLinks();
  const { settings, loading: settingsLoading } = useUserSettings();

  useEffect(() => {
    if (!settingsLoading && settings.newtabEnabled === false) {
      window.location.href = 'about:newtab';
    }
  }, [settings.newtabEnabled, settingsLoading]);

  const showLoader = !authReady || linksLoading || settingsLoading;

  return (
    <div className="newtab__container">
      {showLoader ? (
        <FullscreenLoader />
      ) : null}
      <Header auth={user} />
      <Main auth={user} />
    </div>
  );
}
