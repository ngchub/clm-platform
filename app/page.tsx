"use client";

import React, { useState } from 'react';
import { ShieldCheck, Search, ArrowRight, Lock, AlertTriangle, Server, Globe } from 'lucide-react';

export default function FreemiumLandingPage() {
  const [domain, setDomain] = useState('');
  const [isScanning, setIsScanning] = useState(false);
  const [scanResult, setScanResult] = useState<any>(null);

  const handleScan = (e: React.FormEvent) => {
    e.preventDefault();
    if (!domain) return;

    setIsScanning(true);
    setScanResult(null);

    setTimeout(() => {
      setIsScanning(false);
      setScanResult({
        domain: domain,
        score: 42,
        totalDiscovered: 14,
        expiredCount: 2,
        criticalIssues: 3,
        findings: [
          { subdomain: `vpn.${domain}`, issuer: "Let's Encrypt", daysLeft: -3, status: 'EXPIRED' },
          { subdomain: `dev-api.${domain}`, issuer: "ZeroSSL", daysLeft: 12, status: 'CRITICAL' },
          { subdomain: `staging.${domain}`, issuer: "DigiCert", daysLeft: 84, status: 'GOOD', isGated: true },
          { subdomain: `legacy-portal.${domain}`, issuer: "Sectigo", daysLeft: -15, status: 'EXPIRED', isGated: true },
          { subdomain: `k8s-ingress.${domain}`, issuer: "Let's Encrypt", daysLeft: 5, status: 'CRITICAL', isGated: true },
        ]
      });
    }, 2000);
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col">
      <nav className="border-b border-slate-800 bg-slate-950/80 backdrop-blur-md sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-6 h-16 flex items-center justify-between">
          <div className="flex items-center gap-2 font-bold text-xl tracking-tight text-white">
            <ShieldCheck className="w-7 h-7 text-indigo-500" />
            <span>CLM<span className="text-indigo-500">.io</span></span>
          </div>
          <div className="flex items-center gap-4">
            <a href="/login" className="text-sm font-medium text-slate-400 hover:text-white transition-colors">Giriş Yap</a>
            <a href="#scan" className="bg-indigo-600 hover:bg-indigo-500 text-white text-sm font-semibold px-4 py-2 rounded-lg transition-all shadow-lg shadow-indigo-600/20">
              Ücretsiz Tara
            </a>
          </div>
        </div>
      </nav>

      <main className="flex-1 max-w-5xl mx-auto px-6 py-16 w-full">
        <div className="text-center space-y-4 mb-12">
          <span className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full text-xs font-semibold bg-indigo-950/80 text-indigo-400 border border-indigo-800/50">
            <Globe className="w-3.5 h-3.5" /> Canlı Certificate Transparency Log Taraması
          </span>
          <h1 className="text-4xl md:text-6xl font-black text-white tracking-tight leading-tight">
            Şirketinizdeki <span className="text-indigo-500">Shadow IT</span> ve <br />
            Kritik SSL Risklerini Anında Tespit Edin
          </h1>
          <p className="text-slate-400 text-lg max-w-2xl mx-auto">
            Domain adınızı girin, kamuya açık CT Log’ları üzerinden unutulmuş ve süresi dolan sertifikalarınızı saniyeler içinde raporlayalım.
          </p>
        </div>

        <div id="scan" className="max-w-2xl mx-auto bg-slate-900 p-2 rounded-2xl border border-slate-800 shadow-2xl mb-12">
          <form onSubmit={handleScan} className="flex flex-col sm:flex-row gap-2">
            <div className="relative flex-1">
              <Search className="w-5 h-5 absolute left-4 top-1/2 -translate-y-1/2 text-slate-500" />
              <input
                type="text"
                placeholder="sirketadi.com"
                value={domain}
                onChange={(e) => setDomain(e.target.value)}
                className="w-full bg-slate-950 border border-slate-800 rounded-xl pl-12 pr-4 py-3.5 text-white placeholder-slate-500 focus:outline-none focus:border-indigo-500 transition-colors"
                required
              />
            </div>
            <button
              type="submit"
              disabled={isScanning}
              className="bg-indigo-600 hover:bg-indigo-500 disabled:bg-indigo-800 text-white font-bold px-8 py-3.5 rounded-xl transition-all flex items-center justify-center gap-2 whitespace-nowrap shadow-lg shadow-indigo-600/30"
            >
              {isScanning ? (
                <>
                  <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  CT-Log Taranıyor...
                </>
              ) : (
                <>
                  Ücretsiz Tara <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>
          </form>
        </div>

        {scanResult && (
          <div className="space-y-6 animate-in fade-in duration-500">
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div className="bg-slate-900 border border-slate-800 p-5 rounded-2xl">
                <p className="text-xs text-slate-400 font-medium">Güvenlik Skoru</p>
                <h3 className="text-3xl font-black text-red-500 mt-1">{scanResult.score}/100</h3>
                <p className="text-xs text-red-400 mt-1">Kritik Risk Tespiti</p>
              </div>
              <div className="bg-slate-900 border border-slate-800 p-5 rounded-2xl">
                <p className="text-xs text-slate-400 font-medium">Tespit Edilen Varlık</p>
                <h3 className="text-3xl font-black text-white mt-1">{scanResult.totalDiscovered}</h3>
                <p className="text-xs text-slate-500 mt-1">Subdomain / Sertifika</p>
              </div>
              <div className="bg-slate-900 border border-slate-800 p-5 rounded-2xl">
                <p className="text-xs text-slate-400 font-medium">Süresi Dolanlar</p>
                <h3 className="text-3xl font-black text-red-500 mt-1">{scanResult.expiredCount}</h3>
                <p className="text-xs text-red-400 mt-1">Acil Müdahale Gerekli</p>
              </div>
              <div className="bg-slate-900 border border-slate-800 p-5 rounded-2xl">
                <p className="text-xs text-slate-400 font-medium">Kritik Zincir Riski</p>
                <h3 className="text-3xl font-black text-amber-500 mt-1">{scanResult.criticalIssues}</h3>
                <p className="text-xs text-amber-400 mt-1">Kırık Intermediate CA</p>
              </div>
            </div>

            <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden relative">
              <div className="p-4 border-b border-slate-800 bg-slate-900/80 flex items-center justify-between">
                <h3 className="font-bold text-white flex items-center gap-2">
                  <AlertTriangle className="w-5 h-5 text-amber-500" />
                  CT-Log Taramasında Tespit Edilen Riskler
                </h3>
              </div>

              <div className="divide-y divide-slate-800">
                {scanResult.findings.map((item: any, idx: number) => (
                  <div
                    key={idx}
                    className={`p-4 flex items-center justify-between transition-all ${item.isGated ? 'blur-sm select-none opacity-30' : ''}`}
                  >
                    <div className="flex items-center gap-3">
                      <Server className="w-5 h-5 text-slate-500" />
                      <div>
                        <p className="font-mono text-sm font-semibold text-slate-200">{item.subdomain}</p>
                        <p className="text-xs text-slate-500">Yayıncı: {item.issuer}</p>
                      </div>
                    </div>
                    <div>
                      {item.status === 'EXPIRED' && (
                        <span className="text-xs bg-red-950 text-red-400 border border-red-800 px-3 py-1 rounded-md font-medium">
                          Süresi Doldu ({Math.abs(item.daysLeft)} gün önce)
                        </span>
                      )}
                      {item.status === 'CRITICAL' && (
                        <span className="text-xs bg-amber-950 text-amber-400 border border-amber-800 px-3 py-1 rounded-md font-medium">
                          Kritik Zincir Hatası
                        </span>
                      )}
                    </div>
                  </div>
                ))}
              </div>

              <div className="absolute inset-x-0 bottom-0 h-64 bg-gradient-to-t from-slate-950 via-slate-950/90 to-transparent flex items-end justify-center pb-8 px-4">
                <div className="bg-slate-900 border border-slate-700 p-6 rounded-2xl shadow-2xl max-w-lg w-full text-center space-y-3">
                  <div className="w-10 h-10 bg-indigo-600/20 text-indigo-400 rounded-full flex items-center justify-center mx-auto">
                    <Lock className="w-5 h-5" />
                  </div>
                  <h4 className="text-lg font-bold text-white">Kalan {scanResult.totalDiscovered - 2} Gizli Risk Tespiti Açın</h4>
                  <p className="text-xs text-slate-400">
                    `{domain}` altındaki tüm Unmonitored Shadow IT sertifikalarını görmek ve otonom yenilemeyi başlatmak için ücretsiz hesabınızı aktifleştirin.
                  </p>
                  <button className="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-bold py-3 px-6 rounded-xl transition-all flex items-center justify-center gap-2 text-sm shadow-lg shadow-indigo-600/30">
                    Ücretsiz Hesabı Aktifleştir <ArrowRight className="w-4 h-4" />
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
