package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	// Signal ile iptal edilebilen context oluşturuluyor
	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()

	log.Println("⚡ CLM Multi-Cloud Scanner Engine Başlatılıyor...")

	// Servis arka planda çalışırken context'in iptal edilmesini bekle
	<-ctx.Done()

	log.Println("🛑 Kapatma sinyali alındı, kaynaklar temizleniyor...")

	// Graceful shutdown için kısa bir bekleme süresi
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer shutdownCancel()

	<-shutdownCtx.Done()
	log.Println("✅ Scanner Engine başarıyla kapatıldı.")
}
