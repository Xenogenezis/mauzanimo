const fs = require('fs');
let content = fs.readFileSync('android/app/src/main/AndroidManifest.xml', 'utf8');
if (content.indexOf('FileProvider') === -1) {
  content = content.replace(
    '</application>',
    '        <provider android:name="androidx.core.content.FileProvider" android:authorities="${applicationId}.fileprovider" android:exported="false" android:grantUriPermissions="true">\n            <meta-data android:name="android.support.FILE_PROVIDER_PATHS" android:resource="@xml/file_paths" />\n        </provider>\n    </application>'
  );
  fs.writeFileSync('android/app/src/main/AndroidManifest.xml', content);
  console.log('FileProvider added!');
} else {
  console.log('Already exists');
}
