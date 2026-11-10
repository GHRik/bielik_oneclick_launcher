package bielik.ai.bielik_oneclick_launcher;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.pm.Signature;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import androidx.core.content.FileProvider;
import java.io.File;
import java.security.MessageDigest;
import java.util.Arrays;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;

// Temporary updater for sideloaded APKs. Disabled in Play/AAB builds.
final class ApkUpdateChannel {
    private static final String RELEASE_CERT = "6e6825929a1adb1f9cb3abd7f6051d5a47510832b0464397ea8c9f98de4c28a3";

    static void register(Activity activity, BinaryMessenger messenger) {
        new MethodChannel(messenger, "bielik/apk_update").setMethodCallHandler((call, result) -> {
            if (!BuildConfig.APK_UPDATES) {
                result.error("DISABLED", "Aktualizacje APK są wyłączone w tej wersji.", null);
                return;
            }
            try {
                File directory = new File(activity.getCacheDir(), "app-updates");
                if (call.method.equals("downloadPath")) {
                    if (!directory.isDirectory() && !directory.mkdirs()) throw new Exception("Nie można przygotować miejsca na APK.");
                    File[] old = directory.listFiles();
                    if (old != null) for (File file : old) {
                        if (file.lastModified() < System.currentTimeMillis() - 86400000L) file.delete();
                    }
                    result.success(new File(directory, java.util.UUID.randomUUID() + ".apk").getAbsolutePath());
                } else if (call.method.equals("install")) {
                    if (!(call.arguments instanceof String)) throw new Exception("Brak ścieżki APK.");
                    File apk = new File((String) call.arguments).getCanonicalFile();
                    if (!directory.getCanonicalFile().equals(apk.getParentFile()) ||
                        !apk.getName().endsWith(".apk") || !apk.isFile())
                        throw new Exception("Nie znaleziono pobranej aktualizacji.");
                    PackageManager pm = activity.getPackageManager();
                    int flags = Build.VERSION.SDK_INT >= 28 ? PackageManager.GET_SIGNING_CERTIFICATES : PackageManager.GET_SIGNATURES;
                    PackageInfo installed = pm.getPackageInfo(activity.getPackageName(), flags);
                    PackageInfo archive = pm.getPackageArchiveInfo(apk.getAbsolutePath(), flags);
                    if (archive == null || !activity.getPackageName().equals(archive.packageName))
                        throw new Exception("APK nie jest aktualizacją tej aplikacji.");
                    if (version(archive) <= version(installed))
                        throw new Exception("Pobrana wersja nie jest nowsza od zainstalowanej.");
                    Signature[] incoming = signatures(archive);
                    Signature[] current = signatures(installed);
                    if (incoming.length != 1 || current.length != 1 || !Arrays.equals(incoming[0].toByteArray(), current[0].toByteArray()))
                        throw new Exception("Podpis APK jest niezgodny. Wersji debug z Android Studio nie można zastąpić wydaniem release. Nie usuwaj aplikacji, jeśli chcesz zachować dane.");
                    if (!RELEASE_CERT.equals(hex(MessageDigest.getInstance("SHA-256").digest(incoming[0].toByteArray()))))
                        throw new Exception("APK ma nieprawidłowy certyfikat wydawcy.");
                    if (Build.VERSION.SDK_INT >= 26 && !pm.canRequestPackageInstalls()) {
                        activity.startActivity(new Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                            Uri.parse("package:" + activity.getPackageName())));
                        result.success(false);
                        return;
                    }
                    Uri uri = FileProvider.getUriForFile(activity, activity.getPackageName() + ".app_updates", apk);
                    Intent intent = new Intent(Intent.ACTION_VIEW)
                        .setDataAndType(uri, "application/vnd.android.package-archive")
                        .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                    activity.startActivity(intent);
                    result.success(true);
                } else {
                    result.notImplemented();
                }
            } catch (Exception error) {
                result.error("APK_UPDATE", error.getMessage(), null);
            }
        });
    }

    private static long version(PackageInfo info) {
        return Build.VERSION.SDK_INT >= 28 ? info.getLongVersionCode() : info.versionCode;
    }

    private static Signature[] signatures(PackageInfo info) {
        return Build.VERSION.SDK_INT >= 28 ? info.signingInfo.getApkContentsSigners() : info.signatures;
    }

    private static String hex(byte[] bytes) {
        StringBuilder result = new StringBuilder();
        for (byte value : bytes) result.append(String.format("%02x", value & 255));
        return result.toString();
    }
}
