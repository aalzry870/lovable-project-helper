import { jsPDF } from "jspdf";
import html2canvas from "html2canvas";
import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'app.lovable.f15e381499e74483b68ff385def7f6c6',
  // تم تغيير الاسم هنا ليظهر بشكل صحيح في إعدادات النظام
  appName: 'إدارة المخازن',
  webDir: 'dist',
  server: {
    // الرابط الخاص بك على Render لضمان جلب البيانات عند تشغيل التطبيق
    url: 'https://stock-buddy-pro-25-2.onrender.com',
    cleartext: true
  }
};

export default config;
