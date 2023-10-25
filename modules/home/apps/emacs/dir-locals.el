((nil . ((eval . (setq
                  ;; projectile-project-test-cmd #'helm-ctest
                  projectile-project-compilation-cmd #'helm-make-projectile
                  projectile-project-compilation-dir "build_debug"
                  helm-make-build-dir (projectile-compilation-dir)
                  ;; helm-ctest-dir (projectile-compilation-dir)
                  ))
         (projectile-project-name . "my-project")
         ;(projectile-project-run-cmd . "./run.sh")
         (projectile-project-configure-cmd . "cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..")
         (helm-make-arguments . "-j11"))))
